# Character and animation refinement — 2026-10-31, Asia/Manila

This pass builds on the existing 24-gesture implementation, rather than claiming
that it was absent. Baseline commit: `768741d`. The working tree was clean before
editing. A source checkpoint is saved at `.tools/animation-before-20261031.zip`.
The baseline full Flutter suite passed **56 tests**. The earlier implementation
record is [OVERHAUL.md](OVERHAUL.md); its test counts and APK hashes are historical.

## Asset and runtime audit

| Item | Found at the start of this pass | Decision |
| --- | --- | --- |
| Rendering | Editable Dart paths in `bear_vector_rig.dart`, a local ticker and `CustomPainter` | Refine this free runtime |
| Characters | Existing caramel and white vector heads, ears, facial features, complete torsos and legs; procedural arms | Preserve those shapes, palette and identity |
| Original reference images | No PNG/JPEG/SVG bear references in the project assets; no images attached to this request | Do not claim a reference trace or invent replacement designs |
| Rive | `rive: ^0.14.11` in pubspec; opt-in adapter; `assets/rive/README.md` only | No `.riv` file or editable Rive source to modify/export |
| Spine / Live2D / Lottie / sprite sheets | None | No migration or paid tooling |
| Gesture coverage | All 24 already had distinct working Flutter tracks | No missing gesture is labeled newly completed |
| Placeholders | Rive handoff marker and unavailable external mesh assets; **no static placeholder gesture** in the active Flutter renderer | Keep external deliverables explicitly pending |
| Playback | Contact/recovery/hold, blending, lifecycle suspension, replay, reduced motion already present | Correct input readiness, contact timing and event edges in the same controller |
| Firebase | Auth, pairing, sealed inbox/reveal, delivery, memories, history and rules already separate | No backend/schema/rules/configuration changes |

The initial raster sheets in `artifacts/animations/refined/` are the baseline for
this pass. New sheets use `artifacts/animations/polished/`. Earlier `original/`
artifacts belong to the previous overhaul, not the start of this pass.

## Modified source

| Key | File | Responsibility |
| --- | --- | --- |
| A | `lib/features/animation/presentation/bear_artwork.dart` | Canonical head/torso/mouth contours and layered SVG master export |
| M | `lib/features/animation/presentation/bear_motion.dart` | Varied deterministic blink schedule and stance/swing foot arcs |
| C | `lib/features/animation/presentation/bear_choreography.dart` | Poses, anchors, neck pivot, gesture tracks, guarded inputs and event edges |
| R | `lib/features/animation/presentation/bear_vector_rig.dart` | Continuous eye closure, mouth artwork, feet, ear-base and neck transforms |
| D | `lib/features/animation/domain/gesture_definition.dart` | Typed touch policy, readiness and authored contact/reaction timing for every catalog action |
| S | `lib/features/animation/presentation/bear_scene.dart` | Grounded turn depth ordering, readiness callback and event forwarding |
| P | `lib/features/animation/presentation/player_screen.dart` | Disabled early controls, debounce, guarded walking, replay and background hold release |

No package/dependency was added. Each row below uses Flutter vectors, the shared
rig, and existing Flutter SDK drawing/animation APIs. No animation is downloaded
from Firestore. Catalog IDs, sender/receiver colors and protected payloads are
unchanged.

## Per-gesture audit and implementation record

“Shared foundation” means variable nonsynchronous blinks, a continuous
open/half-closed/closed eye blend, local expression artwork, corrected neck and
ear pivots, and metadata-driven contact events. Arms keep their existing
64-unit reach bound; no mesh weighting or skeletal skinning is claimed.

| Gesture | Current implementation | Asset type | Existing quality | Identified problems | Improvements implemented | Controls / timing | Files modified | Dependencies | Status / limitations |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Warm Hug | Walking, wrap targets, squeeze and hold already worked | Flutter vectors | Working dedicated track; refinement needed | Regular blinking; pendulum feet; center-pivot head/ears | Shared foundation, grounded stance/swing feet for **both** approaching bears, bounded squeeze and existing breath retained | Hold starts only after contact; start/end events; background releases pointer intent | M C R D S P | Flutter SDK / shared rig | Implemented; arms are procedural curves, not weighted skin |
| Cheek Kiss | Nose-to-cheek solve and forward return choreography | Flutter vectors | Working dedicated track; refinement needed | Early tap could replace the initial kiss; no kissing mouth | Neck-based approach and contact re-solve, fading pucker, continuous eye closure | Return accepted after .76; rejected input edges consumed; 280 ms pose blend | A M C R D P | Flutter SDK / shared rig | Implemented; side/profile correction is vector artwork |
| Forehead Kiss | Separate higher target and recipient head dip | Flutter vectors | Working dedicated track; refinement needed | “Kiss back” repeated sender's action | Complementary mirrored acting roles, forward timeline, pucker and neck pivot | Return after .76, independently eased approach/reaction | A M C R D P | Flutter SDK / shared rig | Implemented; no reverse-time playback |
| Hold Hands | Shared paw target and bounded walk | Flutter vectors | Working dedicated track; refinement needed | Input could move bears before attachment; feet only rotated | Stance/swing arcs; phase driven by actual traveled distance; common paw target maintained | Walking accepted from .46; no early queued displacement | M C R D P | Flutter SDK / shared rig | Implemented; screen-space locomotion remains bounded to ±25 |
| Blowing Kisses | Curved heart flight and catch | Flutter vectors | Working dedicated track; refinement needed | Recipient gaze fixed; sender used neutral mouth | Gaze follows heart, pucker blends at blow, smoother eyelids | Catch from .38; contact event delayed to actual arrival .66 | M C R D P | Flutter SDK / shared rig | Implemented; bounded vector heart |
| Good Morning | Sleep-to-wake, stretch and sun | Flutter vectors | Working dedicated track; refinement needed | No yawn; generic contact haptic timing | Local yawn mouth with separate rise/settle, continuous waking eyes and approach feet | Wake input from .30; contact .50 | A M C R D | Flutter SDK / shared rig | Implemented; existing seated sleep opening retained |
| Head Pats | Forehead target and repeated hand oscillation | Flutter vectors | Working dedicated track; refinement needed | Ear rotation used ear center; face closure switched abruptly | Ear-base follow-through, neck-based forehead target, continuous eye closing, approach feet | Repeat after first reaction; contact .46 | M C R D P | Flutter SDK / shared rig | Implemented; paw motion is constrained, not a mesh |
| Nose Boop | Paw-to-nose solve, recoil and return every third tap | Flutter vectors | Working dedicated track; refinement needed | Widening eyes had no mouth reaction; early taps reset motion | Small surprised mouth, continuous blink, neck-aware target and input readiness | Repeat from .68; return counts accepted taps only | A M C R D P | Flutter SDK / shared rig | Implemented; no additional particle load |
| Happy Dance | Lagged rhythm, arm swings, hops and damping | Flutter vectors | Working dedicated track; refinement needed | Facial expression stayed nearly neutral | Happy-eye arc blend, laughing mouth, independent ear lag and stable head features | Reaction must finish before rhythm replay; variants preserved | A M C R D P | Flutter SDK / shared rig | Implemented; reduced motion removes rhythm/hops |
| Piggyback Ride | Crouch, mount, back anchor and walk | Flutter vectors | Working dedicated track; refinement needed | Rider could be displaced before attaching; walking not distance-based | Grounded carrier foot cycle, rider settling/ear lag, calmer rider breathing | Walk enabled after .56; attachment contact at .50 | M C R D S P | Flutter SDK / shared rig | Implemented; rear-facing replacement artwork remains external |
| Tiny Tickles | Irregular wiggle and reachable tickle paw | Flutter vectors | Working dedicated track; refinement needed | Recipient lacked a readable laughing mouth | Happy-eye/laugh blend, restrained torso/head reaction; shared foundation | Repeat readiness and immediate Stop; cancellation event | A M C R D P | Flutter SDK / shared rig | Implemented; Stop still returns through a short pose blend |
| High Five | Raised common paw target and impact burst | Flutter vectors | Working dedicated track; refinement needed | No drawn backswing; arbitrary repeats during impact | Separate withdrawal breakdown, curved reach and recoil, synchronized targets, local reaction | Tap window .24–.57; impact recovery locked until .78 | M C R D P | Flutter SDK / shared rig | Implemented; original light contact haptic preserved |
| Spinning Hug | Entire canvas rotated through 360° | Flutter vectors | Working dedicated track; refinement needed | Somersault effect; shadows stayed on the floor | Upright projected orbit around the shared center; orbit-aware root/head/contact corrections and depth order | Existing approach/contact/recovery and reduced-motion alternative | M C R D S | Flutter SDK / shared rig | Implemented stylized 2D turn; no fully drawn back/side views |
| Cuddle Time | Sitting, lean, eyes shut, optional blanket and hold | Flutter vectors | Working dedicated track; refinement needed | Head/ears rotated at centers; foot motion abrupt on approach | Base pivots, smooth eyelids, coordinated foot settling and shared hold events | Hold extends contact without restarting; gentle release blend | M C R D S P | Flutter SDK / shared rig | Implemented; rigid torso with local compression |
| Goodnight Kiss | Blanket, forehead contact and dimming | Flutter vectors | Working dedicated track; refinement needed | Recipient reopened eyes after the kiss | Recipient remains asleep through final pose; delayed head settling; pucker at kiss | Input after .78; no premature repeat interrupts sleep | A M C R D P | Flutter SDK / shared rig | Implemented; opening is tucked/seated, not a new flat-bed drawing |
| Sleep Together | Recline, shared paw target, blanket and breathing | Flutter vectors | Working dedicated track; refinement needed | Shallow recline; identical ear behavior | Deeper recline with corrected root spacing, reachable paw target, infrequent delayed ear twitch | Cozier input after .50; wake swipe remains a safe interruption | M C R D P | Flutter SDK / shared rig | Implemented reclined pose; fully horizontal replacement artwork pending |
| Comfort Hug | Slow approach and sad-to-comforted recipient | Flutter vectors | Working dedicated track; refinement needed | Recipient body posture too similar to warm hug | Initial softened torso, slower expression relief, restrained blush, both-bear step arcs | Hold/contact events and release; slower existing 9.6 s duration | M C R D S P | Flutter SDK / shared rig | Implemented; no external cheek/torso mesh |
| Dry Your Tears | Reach, curved wipe, fading tear and smile | Flutter vectors | Working dedicated track; refinement needed | Head pivot did not use neck; early touch could bypass approach | Neck-aware cheek target, smooth face recovery and guarded early wipe | Input from .30; existing eased wipe and tear fade retained | M C R D P | Flutter SDK / shared rig | Implemented; vector tear, no fluid simulation |
| I Miss You | Seated sadness, sender joins, paw contact | Flutter vectors | Working dedicated track; refinement needed | Gaze turned only with the smile; generic contact event too early | Eyes notice first (.32–.46), head remains lowered until relief, separate paw event | Paw contact .63; note input retains existing protected payload behavior | M C R D | Flutter SDK / shared rig | Implemented; sender remains visible at opening |
| One Umbrella | Prop follows handle; input brings bears closer | Flutter vectors | Working dedicated track; refinement needed | Early input before shared shelter; center-pivot reactions | Guarded closeness, corrected head/ear pivots and smooth eyelids; existing handle sway retained | Input/contact .50, reaction .58 | M C R D P | Flutter SDK / shared rig | Implemented; existing window-rain scene retained |
| A Little Flower | Hidden offer, handoff, bloom and wobble | Flutter vectors | Working dedicated track; refinement needed | Surprise face used neutral mouth; generic event too early | Small surprise mouth, neck tilt and continuous expression, approach feet | Reveal/bloom from .45; presentation event .53 | A M C R D P | Flutter SDK / shared rig | Implemented; five vector petals, no external flower rig |
| Heart Delivery | Carry, stumble, curved offer and acceptance | Flutter vectors | Working dedicated track; refinement needed | Neutral mouth at reaction; regular blink | Local surprise mouth, corrected neck/ears, foot swing through weighted approach | Input from .45; presentation event .53; existing damped stumble retained | A M C R D P | Flutter SDK / shared rig | Implemented; authored prop weight, not a physics simulation |
| A Tiny Surprise | Planted box, lid lift and pop | Flutter vectors | Working dedicated track; refinement needed | Box did not shake during anticipation | Bounded 1.2-unit shake before reveal, small surprise mouth and neck-aware startle | Unwrap after .43; reveal contact .68; reaction .70 | A M C R D P | Flutter SDK / shared rig | Implemented; no random gift inventory |
| A Shy Confession | Nervous gaze, breath/pause, late offer and blush | Flutter vectors | Working dedicated track; refinement needed | Generic contact event preceded the offered heart | Late contact/reaction events, tiny surprised mouth, neck-based head tilt and approach feet | Read/reveal from .63; separate recipient reaction .68 | A M C R D P | Flutter SDK / shared rig | Implemented; no replacement reference trace |

## Architecture and preservation

`BearPlayback` remains the single owner of elapsed scene time. The new typed
definition supplies touch policy and contact/reaction milestones. Events are
started, approach complete, contact started, reaction started, interactive hold
started/ended, completed and cancelled. Milestone events fire once per run;
hold edges may repeat. The existing completion callback is retained for app
integration. A Stop/wake interruption emits cancellation, blends to rest and
then finishes recovery using that existing completion contract.

Rejected early tap edges are consumed, so a later settings rebuild cannot
replay them. Accepted taps are counted separately from incoming sequence
numbers. Input retargeting preserves the current pose and blends forward.
Early walking is ignored, rather than stored for later. The player disables
unready buttons and guards scene taps/drags; Stop, wake and explicit replay
remain available. Hold intent may be requested during approach, but the
timeline can only freeze at the established .64 contact/hold pose.

The scene exposes optional `onEvent` and readiness callbacks. Repaints remain
driven by the playback listenable, without rebuilding the whole screen every
frame. Existing background/TickerMode suspension, reduced-motion settling,
controller disposal, audio mute and haptic preferences are preserved.

The runtime uses smooth cubics for approach/recovery, smoothstep for blink and
foot swing, sine arcs for reaches/orbit, and bounded damped settling. These are
layer transforms and procedural contours, **not deformable mesh skinning**.
Particles remain bounded and no continuous haptic or audio loop was added.

## Editable artwork and remaining external work

Generated 1024×1024 transparent master SVGs are in
`artifacts/animations/masters/brown.svg` and `white.svg`. Their head, torso and
neutral mouth share the runtime contour source. Named groups separate the
complete lower body, feet, arm sections, paws, ears, eyes, cheeks, nose and
mouth; hidden expression alternatives are selectable in a vector editor.
These are authoring masters derived from the existing artwork. They are not
new runtime asset duplicates and do not claim accurate tracing of unavailable
original reference images. See [ARTWORK.md](ARTWORK.md) for coordinates, pivots,
export/reconstruction steps and what remains manual.

The workbench now includes variants, one-frame advancement, readiness-aware
reaction controls and the latest event edges. The standalone profile harness
cycles all 24 gestures with both sender colors locally. It contains no Firebase
initialization or real message delivery. Physical Android testing, haptic
acceptance, actual reference-image comparison, horizontal sleeping drawings,
fully authored rear-view turn/piggyback art and external Rive/mesh authoring
remain pending. The optional Rive adapter is unchanged and no export or paid
Rive subscription was attempted.

Verification results and reproducible commands are recorded in
[REFINEMENT_QA.md](REFINEMENT_QA.md). Existing authentication, navigation,
accounts, pairing, inbox/reveal, delivery, history, memories, settings and all
Firestore collections/rules remain outside this diff.
