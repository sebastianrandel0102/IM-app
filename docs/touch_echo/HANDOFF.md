# Touch Echo implementation and verification

Implemented in the existing application on 1 November 2026. This is a release
candidate with automated and rendered-frame verification. Physical two-device
feel, native frame rate, and final artistic acceptance still require devices.

## User experience

Home → **Touch Echo · Send your actual touch** opens the user's own assigned
bear. Finger contact immediately drives articulated head, ear, eye, torso and
paw responses. A completed, valid touch offers a named preview. Select gentle,
normal or playful, preview the two-bear action, then explicitly Send This Touch.
No send occurs on recognition, preview, notification, or animation completion.

An unopened inbox entry says **Open Touch Echo** and contains no selected touch,
thumbnail, parameters, note, or animation. The envelope's Open action commits a
receiver-only authorization transition before fetching the protected payload
from the server. Playback offers Skip, Replay, private Save Memory, Close and
Touch Back. Touch Back creates a new immutable event linked to the completed
received Echo. Sender and recipient bears follow the active pair assignment.
Sender history can replay the outgoing Echo but cannot send a reply to itself.

There is no character dialogue, quote card, speech bubble, microphone, voice,
AI conversation or speech recognition in Touch Echo. Existing optional legacy
nonvocal audio initializes only when enabled and used. Touch Echo is silent.

## Files and phase verification

| Phase | Implementation and files | Evidence / remaining acceptance |
| --- | --- | --- |
| 0 audit | AUDIT.md; complete master prompt, routes, rules, assets, settings, auth/pairing, tests and scripts inspected | Flutter 3.47.7 / Dart 3.13.5; four references inspected inline; no local reference PNGs |
| 1 rig | bear_choreography.dart, bear_vector_rig.dart, touch_geometry.dart | Additional anatomy anchors and per-ear bend controls; moving hit zones; debug anchor review |
| 2 input | touch_classifier.dart, touch_input_controller.dart, touch_intent.dart | Head stroke, boop and paw hold positive/negative cases; double-tap suppression; cancellation and normalized mapping |
| 3 acting | touch_playback.dart, touch_stage.dart, bear_physics.dart | Rendered paw reach checks at 30/60 simulation steps; both character assignments rendered; fixed-step springs |
| 4 preview/send | touch_mode_screen.dart, touch_echo_repository.dart, app.dart, home_screen.dart | Actual pointer widget test, preview and explicit send; persistent pending ID, acknowledgment and restart tests |
| 5 reveal | models.dart, inbox_screens.dart, player_screen.dart, firestore.rules | 41 security tests pass; real Auth/Firestore emulator delivery and restricted reveal; production rules deployed |
| 6 Touch Back | protected replyToEventId; current player/Touch Mode routes | Emulator reverse-role reply, completion eligibility, memory and idempotent retry pass |
| 7 ten touches | TouchKind, TouchClassifier and TouchPlayback | Ten recognizers and ten distinct contact/reaction tracks; all styles; circle directions and false-positive cases |
| 8 accessibility | settings_repository.dart, settings_screen.dart, touch_haptics.dart, authentication_repository.dart | Accessible action list, hints, sensitivity, haptic presets, reduced motion, receive pause, local-data/logout clearing; 320 px / 2× text test |
| 9 regression | four new test files; existing test suite; rules.test.mjs, two-client.mjs; review/profile tools | 104 Flutter tests pass, analyzer clean; device acceptance remains |
| 10 future live | No new live-touch implementation | Deferred. Existing Together feature is preserved |

New files are under `lib/features/touch_echo/{domain,data,presentation}`.
Existing affection types, their 24 identifiers, and legacy stored payloads are
preserved. ProtectedMomentPayload accepts an optional validated TouchIntent;
the legacy interactionType is only an adapter for existing routes/memories.
Memory captions use the touch title. No dependencies were added.

## Rig, anchors and contact

The existing editable Dart vector rig has separate torso, rigid head/neck,
near/far arms, two-link bend handles, paws, ears, feet, eyes, cheeks and muzzle.
There is no flattened model-sheet sprite or claimed Rive export. Stage units are
400×340; finger samples use stage units divided by 100. Local camera zoom and
letterboxing are inverted before hit testing. Head/body transforms and mirrored
facing are shared with rendering. Facial features remain rigid under torso
compression; the readable ear mark remains consistent between roles.

| Anatomy | Local coordinates / definition |
| --- | --- |
| head_center, head_top, forehead | headPoint(0,0), headPoint(0,-57), headPoint(35,-45) |
| left_ear, right_ear | head-local ear pivots plus the actual independent bend/lag rotation |
| nose, muzzle | profile-adjusted headPoint(9+43×turn,25/31) |
| cheeks | profile-adjusted headPoint(x,28), the same coordinates as the painted cheeks |
| shoulders / arm_near, arm_far | bodyPoint(±23,-80) with authored reach/embrace corrections |
| paws | Two-link endpoint clamped to 64 stage units from its shoulder |
| chest, belly, back | bodyPoint(0,-65), bodyPoint(0,-40), bodyPoint(-22,-85) |
| hug_center, head_rest, feet | existing posed hug/head-rest and grounded pose-specific foot anchors |

Hit-test priority: ears → nose → cheeks → paws → head → exposed outer shoulder
→ chest → belly. Ellipses follow the current rig, with generous containment for
small boundary crossings. The debug anchor switch is available in the local
review harness and disabled in production. Hints are an optional overlay.

TouchPlayback V1 authors anticipation, grounded approach, reach, contact, hold,
reaction, release and return. Head Pet uses a seated corrective recipient pose,
raised sender shoulder, and a short skull-surface arc. The actual rendered paw,
including reach clamp, is checked against the target. Face masking and foreground
arm layering keep the reaching arm readable. Hug uses staggered near/far wraps;
paw hold uses one common contact; Back Comfort uses the accessible outer-shoulder
variant. Ear Rub targets the reachable near ear rather than reaching across the
head. Heart Trace is a canonical luminous heart landing toward the chest.

Styles change authored duration/amplitude, reaction and spring damping. Primary
poses are followed by bounded 60 Hz semi-implicit spring motion, a maximum eight
catch-up steps, and a final contact solve. Body squash, joint reach and head tilt
are bounded. Backgrounding clears held input and simulation backlog; hidden
scenes use Flutter ticker visibility. Idle stable local scenes stop ticking.

## Recognition and local privacy

| Touch | Recognition |
| --- | --- |
| Gentle Head Pet | Coherent head stroke, ≥250 ms, meaningful displacement, bounded speed |
| Nose Boop | Small displacement, 30–350 ms; compatible second tap within 300 ms produces one double-boop intent |
| Cheek Caress | Slow coherent cheek stroke |
| Paw Hold | ≥650 ms with low movement on a paw |
| Belly Rub | Closed circular path, adequate width/height, curvature, radius consistency and dwell; either direction; inward heart notches are rejected |
| Ear Rub | Small back-and-forth ear motion with a direction reversal |
| Hug Hold | ≥800 ms still chest contact |
| Back Comfort | ≥450 ms slow coherent stroke on the exposed shoulder/back zone |
| Heart Trace | Explicit Draw a Heart mode; bounded closed contour compared against an authored heart; a circle/scribble is rejected |
| Tiny Tickle | At least three small, rapid belly-stroke reversals in a short time window |

Samples have monotonic local timestamps, no OS hardware identifiers, and a
2048-sample cap. Invalid timing, huge jumps, fast swipes, off-character starts,
route/pointer cancellation, and multi-pointer ambiguity do not force a touch.
Reversal thresholds suppress tremor. High-resolution samples are cleared after
classification/cancellation. Pressure is neither required nor inferred as force.
Only type, zone, style, intensity, duration, direction, count and seed are stored.
The heart is an interpreted semantic heart rather than archived handwriting.

## Schema and authorization

Existing paths remain:

```
couples/{activeInvitationId}/moments/{stableEventId}   # generic envelope
couples/{activeInvitationId}/payloads/{stableEventId}  # restricted immutable data
couples/{activeInvitationId}/memories/{uid}_{eventId}  # private saved reference
couples/{activeInvitationId}/touchPreferences/{uid}   # receiveTouches boolean
couples/{activeInvitationId}/touchSendLimits/{uid}    # server time + last event
```

A touch envelope adds only `kind: touch_echo` to the existing senderUid,
receiverUid, createdAt, openedAt, playedAt and fixed genericLabel. The protected
payload retains the existing role/type fields and adds `touch` plus a nullable
`replyToEventId`. Touch schema V1 contains:

```
schemaVersion: 1
kind / zone / style: strictly enumerated, mutually consistent
intensity: 0.15..1       durationMs: integer 350..6000
seed: integer 0..2147483647
direction: -1..1        repetitions: integer 1..3
animationId: touch_{kind}
animationVersion: 1
```

Unknown fields, trajectories and unsupported versions are rejected. V1 code is
retained as a replay contract; an unsupported future schema asks for an update.
No gesture details enter the envelope, inbox query or memory before eligibility.

Creation atomically writes envelope, payload and server-enforced two-second
send limiter. Rules derive the permitted users and complementary bears from the
existing membership/pair model, validate keys/ranges/adapter consistency, deny
immutable edits and duplicate overwrites, and honor recipient pause. Reply
references must point to an opened and completed received Touch Echo in this
same active world. Only the receiver can first set openedAt and playedAt, both
to server time. Replay never rewrites openedAt. Listing protected payloads is
denied. Revocation/re-pairing denies old world server reads and pending writes.

The existing fixed two-account allowlist remains the membership authority;
Touch Echo introduces no hardcoded UID. Reveal is a Firestore access-state
boundary, not cryptographic proof of a physical tap or end-to-end encryption.
Project administrators retain ordinary database access.

## Pending, retry, settings and cost

Send stores one bounded semantic intent and stable ID in SharedPreferences,
scoped to both UID and invitation ID. A transaction checks current active pairing,
recipient preference and existing ID. A matching accepted event is acknowledged
without another event. Content mismatch is rejected. UI shows Pending until
server acknowledgment, even after a network error. Pending attempts back off
3/8/20/60 seconds; no recurring timer runs when there is no pending intent.
Session restart restores only the matching authenticated pair's pending intent.
Permission/revocation failures stop automatic retries. Logout removes account
outboxes. Clear Local Data cancels pending retries, provided an active commit
has finished. An already committed send cannot be undone by canceling a local
draft. Preview and local reaction work offline. First reveal requires online
authorization; previously opened payloads use the existing session-only replay
cache. Firestore disk persistence remains disabled.

Haptics have an off switch and user strength preference selecting restrained
platform presets; hardware behavior varies. Motion reduction preserves the
intent with bounded simplified poses. Receive Touch Echoes pauses future
creation server-side. Existing notification mute and unpair remain available.

The feature uses the existing Auth + Firestore baseline. No Functions, Storage,
FCM sending credential, remote inference, video upload, billing upgrade or live
frame synchronization was introduced. One fresh send writes three small docs;
opening, completion and personal memory each write once. Inbox/history retain
existing 30-document pagination. Samples and physics frames never write online.
Push requires a separately authorized trusted sender; the baseline is in-app
listeners. See [Firebase plans](https://firebase.google.com/docs/projects/billing/firebase-pricing-plans),
[transactions](https://firebase.google.com/docs/firestore/manage-data/transactions)
and [field rules](https://firebase.google.com/docs/firestore/security/rules-fields).

## Automated, visual and operational evidence

- `flutter analyze`: final clean run, no issues.
- `flutter test --reporter expanded`: final 104 tests passed. Includes all legacy
  gesture tests, recognizer false positives, actual pointer reaction before
  release, 30/60-step contact constraints, background/multi-touch cancellation,
  320 px / 2× text, preview, reveal completion, Touch Back navigation and outbox
  restart/idempotency checks.
- The final six-test domain rerun also advances actual style-tuned secondary
  impulses and checks both front and rear rendered hug endpoints during full
  contact. The final one-test screenshot rerun verifies the receiver's own bear
  assignment on Touch Back and absence of legacy dialogue/quote cards.
- A final false-positive regression confirms a heart drawn on the belly outside
  explicit heart mode remains ambiguous rather than becoming a Belly Rub.
- `.\scripts\test-backend.ps1`: 41/41 rules tests and real two-client
  Auth/Firestore integration passed against `demo-bear-with-me`.
- Integration includes registration/pairing, live listener arrival, denied sealed
  reads, explicit reveal, completion, matching-ID retry, reversed Touch Back,
  private memory, sign-out/sign-in and revoked pairing. No production message was
  sent as a test.
- `.\scripts\firebase.ps1 deploy --only firestore:rules --project
  bear-with-me-f60a3 --non-interactive`: compiled and released successfully.
- Android debug and final release builds succeeded. The signed release APK is
  86,278,315 bytes; APK Signature Scheme v2 verified. Packaged code contains
  Touch Echo, the existing members and correct Firebase project, and no emulator
  project or service-account file. Manifest inspection confirms no microphone,
  camera or location permission. Details are in `artifacts/touch_echo/verification.json`
  and `apk-verification.json`.
- The isolated web-profile run completed all 20 touch/bear assignments: 6,316
  timing samples, build p95 2.7 ms, raster p95 2.0 ms, total frame-span p95
  5.101 ms, four samples over 16.667 ms. This is a web observation during this
  session, not native GPU/60 Hz acceptance. See `profile-web.json`.
- `git diff --check`: passed, with repository line-ending notices only.
- `adb devices -l`: no attached devices. iOS compilation and native hardware
  profiling were not performed.

Actual production painting was rendered into `artifacts/touch_echo/`:
`contacts-brown.png`, `contacts-white.png` contain all ten interactions at
0/.18/.34/.50/.65/.80/.93/1; `touch-mode.png` and `preview.png` are local app
screens after an actual synthetic head stroke. The `*-fixture.png` inbox,
envelope, reveal and Touch Back screenshots use explicitly named rendering
fixtures, not a claim of production account delivery. Both role sheets and the
Head Pet foreground paw/crown contact, readable faces, seated feet, hug wraps,
releases and settled poses were visually inspected. Such frames do not establish
subjective animation polish or native touch latency.

Early checks encountered and resolved: conditional-expression parse errors;
an unused test import; stale snapshots from editing while preliminary checks
were running; far-ear and far-shoulder reach errors; a rules fixture using an
unsupported nested array; eager legacy audio plugin initialization in silent
playback; and a legacy preset quote card in Touch Echo. Initial checks overlapped
edits and are not a pristine pre-change test baseline. A redundant emulator
launch encountered occupied ports; the main sequential backend suite passed.
Browser diagnostic probes had shell-quoting/module-loader failures. The first
browser profile loaded a stale cached legacy harness and was rejected as Touch
Echo evidence; only a report naming all 20 Touch Echo scenes is acceptable.
That first observer timed out; a fresh browser with cache bypass produced the
valid 20-scene profile. The Python APK helper could not run because Python is
not installed; equivalent .NET ZIP inspection, aapt permission inspection and
apksigner verification succeeded.
Native build tooling emits existing Kotlin-plugin migration/deprecation notices.

## Two-device acceptance

1. Install the final signed APK on both devices; sign into the already authorized
   accounts and confirm the existing pairing. No credentials are needed in code.
2. Sender opens Touch Echo. Stroke the upper head slowly; confirm immediate
   head lean, softened eyes, ear lag and calm recovery before sending anything.
3. Preview Gentle Head Pet, verify recipient and style, then press Send once.
   With airplane mode, confirm Pending rather than Delivered; reconnect and
   confirm exactly one outgoing entry, including after restarting the app.
4. On the partner device, confirm a generic unopened envelope and no autoplay or
   touch title. Deliberately Open, then check paw/crown alignment and both bear
   identities through approach, hold, release and settling.
5. Replay and verify the original opened timestamp is preserved. Save to the
   private memory book, favorite, replay and remove the reference.
6. After completion, Touch Back, perform a Paw Hold and send it. The other device
   must now see the roles reversed and a newly sealed envelope linked to the
   original Echo. Confirm the sender cannot reply to its own outgoing event.
7. Repeat each guided input from the ten-touch table, including both circle
   directions and deliberate heart mode. Tune sensitivity only if necessary.
8. Try both styles of bear assignment, small/large screens, landscape, screen
   reader action alternatives, large text, reduced motion and haptics off.
9. Background during a hold, interrupt with a second finger, exit during preview
   and rapidly retry send/replay. No stuck paw or duplicate event should remain.
10. Pause receiving, confirm a new send is refused; unpair with an unsent pending
    touch and confirm old-world reads/sends fail. Inspect battery/memory and
    native frame timings during repeated playback before production sign-off.

For local frame scrubbing/anchors:
`flutter run -t tool/touch_echo_review.dart -d chrome`.
For real native timing:
`flutter run --profile -t tool/touch_echo_profile.dart -d DEVICE_ID`.
`/studio/touch` is intentionally offline/local-only and cannot send an Echo.
