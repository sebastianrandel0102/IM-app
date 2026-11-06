# BEAR WITH ME — TOUCH ECHO: SEND YOUR ACTUAL TOUCH
## Complete Advanced Flutter, Firebase, 2D Character Animation, Interaction Physics, Security, and QA Implementation Master Prompt

### 0. REQUIRED ROLE AND MISSION

You are simultaneously the senior Flutter/Dart engineer, Firebase architect, 2D game interaction programmer, professional 2D character rigging artist, animation director, physical animation engineer, mobile UX designer, accessibility reviewer, security reviewer, and QA lead for my existing application, **Bear With Me**.

Implement a production-quality feature named **Touch Echo — Send Your Actual Touch** inside my existing Flutter application at **D:\VS Files\IM-app**. Do not create an unrelated demo, a new app, a generic pet game, or a separate replacement project. First inspect the repository and use its current architecture, design language, routes, packages, models, authentication, Firebase project, Firestore rules, and working features. Preserve existing functionality and the 24 gestures.

The concept: one partner physically touches their own animated bear on the screen. The app detects body zone, finger motion, contact duration, rhythm, and interaction intensity; responds instantly through expressive, physically plausible local animation; then offers an explicit preview and Send This Touch action. The other partner receives a private unopened Touch Echo, deliberately opens it, and watches a beautifully coordinated scene where the sender's bear recreates the meaningful contact on the receiver's bear. The recipient may replay, save a private memory, or touch back.

Touch Echo must preserve the essential artistic illusion of a personal touch. This means transferring an interpreted touch gesture with selected expressive parameters, not pretending the phone can reproduce literal human skin sensation or streaming every touch sample/physics frame over Firebase.

### 1. NON-NEGOTIABLE RESTRICTIONS

1. **ABSOLUTELY NO TALKING FEATURES**: no microphone, audio recordings, synthetic voices, voice AI, speech recognition, lip synchronization, dialogue, chatbots, speech bubbles, or character conversations. Characters express emotion through posing, eye motion, facial expressions, ears, body language, contact, haptics when consented, and optional nonverbal sound effects only.
2. Preserve the original white-bear and caramel-brown-bear character identities, colors, face proportions, cheeks, muzzle, asymmetric ear marks, thick rounded outline, and soft minimal aesthetic. No generic replacement bears, 3D redesign, realistic fur, anime eye treatment, clothing redesign, or unrequested accessories.
3. Preserve the existing two-person account pairing and login. Only authorized paired partners may exchange Touch Echoes. Neither UID should be hardcoded.
4. Keep the receiver's deliberate open-to-reveal experience. An unopened Echo must never autoplay when a notification is received or a background listener fires.
5. **Firebase Spark plan first**: do not silently upgrade to Blaze, introduce paid cloud products, require Cloud Functions deployments, or ship service credentials in the client. If an optional capability truly requires a paid backend or trusted sender, present a secure Spark-compatible baseline and explain the upgrade as an option requiring approval.
6. Do not break, remove, silently rename, or change the data formats of the 24 existing gestures. Integrate with them, adding migrations/adapters only when necessary.
7. Never claim an attachment, screenshot, animation preview, test, build, Firebase rule deployment, or device interaction was inspected/performed unless it actually occurred. If any prerequisite is missing, clearly state it and keep making safe progress where possible.
8. Do not request passwords, service-account private keys, or leaked credentials.
9. Respect reduced motion, touch accessibility, optional haptic preferences, poor network conditions, and device size differences.
10. Make high-quality gestures and animation verification an acceptance criterion, not merely successful Dart compilation.

### 2. FOUR IMAGE REFERENCES AND CHARACTER INTAKE

The user has four supplementary generated reference images from the earlier character and physics development phase. If attached or placed in the repository, inspect all four before reconstructing art:

1. assets/reference/01_white_bear_character_sheet.png — six poses for the white bear: front, three-quarter, profile, seated, sleeping, open arms. Use for white bear's consistent layered rig.
2. assets/reference/02_brown_bear_character_sheet.png — analogous six-pose model sheet for the brown bear. Use for proportional harmony, short limbs, cream muzzle, and rig construction.
3. assets/reference/03_hug_cuddle_storyboard.png — warm hug approach, wrapping, hold, release, and seated cuddle staging. Use to define believable touch contact and cooperative body placement.
4. assets/reference/04_touch_physics_storyboard.png — head pet, nose boop, belly tickle, paw hold, spinning hug, and sleeping touch/physics ideas.

The original two user illustrations, if supplied, have final authority over character identity:

- assets/reference/00_original_white_bear.png
- assets/reference/00_original_brown_bear.png

A text prompt does not itself upload binary images. First create a reference audit with actual accessible paths, dimensions, inspected content, and missing-file status. If four supplementary images are missing, do not pretend to have viewed them. Continue code audit and nonvisual planning, and request only the required missing asset before identity-sensitive reconstruction. Do not misuse a whole model sheet as a production sprite texture.

Reference priority: original drawings > stable anatomy/identity > generated character sheets > generated storyboards > generic style opinions.

### 3. REQUIRED INITIAL REPOSITORY AUDIT

Before changing the project:

1. Confirm the exact project root and Flutter/Dart versions already installed.
2. Read project-specific instructions, README, analysis options, build scripts, asset manifests, routing, theme, and dependency configuration.
3. Find currently active white/brown bear rendering and animation assets, scene controllers, state management, model classes, gesture IDs, UI routes, tests, and custom painters/Rive/Flame/Spine integrations if any.
4. Inspect Firebase initialization, current Firebase Auth configuration, pair membership model, Firestore collections, Security Rules, indexes, inbox, reveal events, memory screen, notification implementation, and settings.
5. Determine whether genuine layered editable art exists or the current app merely moves flattened PNGs.
6. Identify exact source files touched by the new feature, and avoid wholesale replacement of existing app architecture.
7. Determine what gesture definitions must be reused and where an adapter is more appropriate than a rewrite.
8. Note the current state of Spark billing compatibility; never assume a background push sender exists.
9. Provide a brief implementation map listing actual code locations, current capabilities, missing dependencies, and immediate risks.
10. Establish build, analyzer, test, and screenshot baselines to detect unrelated regressions.

### 4. FEATURE DEFINITION AND SUCCESS CRITERIA

Touch Echo is a complete loop:

LOCAL TOUCH -> IMMEDIATE LOCAL BEAR REACTION -> GESTURE CLASSIFICATION -> REPLAYABLE PREVIEW -> EXPLICIT SEND -> PRIVATE INBOX ENVELOPE -> RECEIVER OPENS -> PAIR ANIMATION -> OPTIONAL TOUCH BACK / REPLAY / SAVE MEMORY.

The primary use case is **asynchronous** and must work even when partners are not simultaneously online. Optional Live Touch is a later, separate permission-based phase; it may not block the asynchronous MVP.

Definition of success:

- User feels direct, low-latency feedback touching a believable live character.
- The character's reaction changes meaningfully according to body zone, gesture, duration, and chosen intensity.
- Finger input does not accidentally manipulate the whole character or trigger unrelated navigation.
- A touch event can be previewed, canceled, sent, and accurately delivered.
- Receiver's unopened item is visually neutral and intentionally opened.
- Sender and receiver bear roles are correct, reversible, and consistent with account assignments.
- The sender's bear physically acts on the receiving bear with correct paw/head contact rather than random floating hearts.
- Replaying reproduces the intended meaningful action with stable, tasteful variation.
- The receiver can respond with a new touch, preserving an explicit threaded connection.
- All personal events are visible only to an authorized pair.
- The experience remains charming, silent, performant, and reasonably Spark-friendly.

### 5. CHARACTER, RIG, AND TOUCH ANATOMY

Preserve a single consistent scene unit system. Each bear rig must expose:

- root/world transform;
- body/torso with adjustable squash axis;
- head pivot with comfortable tilt limits;
- near/far ears;
- near/far arms, elbows or suitable bend handles, and paws;
- short legs/feet and an effective grounded foot/contact constraint;
- eyes, cheeks, nose, mouth/muzzle, facial expression controls;
- layer order suitable for two-bear contact;
- a soft ground shadow;
- alternate correction shapes or authored poses where deformation would look distorted.

Publish anatomy anchors in the rig's local coordinates, transformed into world space per frame:

- head_center, forehead, head_top, left_ear, right_ear;
- cheek_left, cheek_right, nose, muzzle;
- shoulder_left, shoulder_right, back, chest, belly;
- paw_left, paw_right, arm_near, arm_far;
- hug_center, head_rest, foot_left, foot_right.

Use rig-attached interactive collision shapes (ellipses, capsules, polygons, or art-driven hit regions) instead of hardcoded global screen rectangles. Recompute hit zones through the character's actual camera, stage, and part transforms; handle mirrored poses carefully without reversing asymmetric ear or facial features. Near/far body parts must be separately addressable for proper occlusion.

If the reference art is flattened, produce true layered editable source sprites/vector paths or a comparable supported runtime rig. An animation-ready character must NOT be represented by one unarticulated full-body picture that scales and rotates for every action. Author contact-specific corrective drawings where needed.

### 6. THREE MODES OF INTERACTION

**Mode A: Local Touch (MVP, no network)**:

- User touches the bear with a pointer on the home scene or dedicated Touch Mode screen.
- Bear reacts immediately and authentically.
- Gesture recognition processes the completed interaction into a compact event.
- User may discard, repeat, or prepare a send.

**Mode B: Send/Receive Touch Echo (MVP)**:

- User reviews the most recent valid local touch, previews it, and explicitly sends.
- Recipient receives a sealed inbox item. It may show the sender and generic affection indication but not spoil the selected touch.
- On Open, the receiving client obtains the payload through the authorized reveal path and plays sender-bear-to-receiver-bear choreography.
- Recipient may Touch Back, Replay, Save, or Close.

**Mode C: Live Together Touch (future, opt-in)**:

- Two online users expressly join a session.
- One partner's deliberate local interaction event can drive a short shared response.
- Consent and session participation are mandatory, and disconnection returns safely to idle.
- Sync high-level intents and time markers only, never raw 60 FPS physics states or unrestricted remote pointer paths.
- Do not build live mode until asynchronous Touch Echo is functional and tested.

### 7. TOUCH SCREEN UX — STATEFUL DESIGN

Design a beautiful Touch Mode with:

- white/brown bear as the unmistakable focal point;
- tiny nonintrusive instructions, e.g. 'Touch your bear gently';
- subtle hints for head, cheeks, paws, belly;
- optional touch guidance overlay, dismissible;
- a clear Exit Touch Mode control;
- reduced obstruction during direct manipulation;
- optional nonverbal haptics and silent setting;
- animation reaction that respects a valid hit zone;
- a transient floating affordance to Preview / Send This Touch once a valid gesture is completed.

Do NOT cover the bear with full-screen invisible touch zones that intercept system navigation. Do NOT let the stage consume accessibility focus. Ensure hit zones are generous but separated enough to avoid ambiguous input. Use semantic alternative buttons or an accessible action list for users who cannot perform drag gestures.

Preview screen:

- brief on-device replay;
- detected interaction name;
- gentle/normal/playful style;
- duration indicator;
- explicit recipient display;
- Send Touch, Retry, Cancel buttons;
- visible sending, pending, delivered, failed states;
- animations must be cancellable without duplicate sending.

Inbox envelope:

- soft heart/gift icon and a generic unseen preview;
- optional sender and timestamp;
- unmistakable 'Open Touch Echo' action;
- no pre-open autoplay, full gesture thumbnail, gesture name, or spoiler text;
- notification opens the envelope route, not the playback route.

Reveal scene:

- both bears on a consistent stage;
- sender-bear entrance or established position;
- intentional approach, contact, reaction, graceful release;
- short skip and replay controls;
- reduced-motion fallback;
- Touch Back, Save Memory, Close actions after completion;
- completion tracked distinctly from opened state.

### 8. GESTURE RECOGNITION ENGINE

Capture pointer lifecycle via the existing Flutter input system, using a suitable combination of low-level Listener, hit testing, and higher-level gesture recognizers. Do not assume every touch system can reliably deliver OS pressure values. Treat device pressure as optional and never required.

For each active local touch:

1. Determine target bear and rig-attached hit zone on pointer down.
2. Convert screen input into stable rig-local normalized coordinates.
3. Record local monotonic timestamps and an ephemeral pointer sequence.
4. Maintain an appropriate low-pass or one-euro-style filter if helpful, without introducing unacceptable input lag.
5. Compute path length normalized by head/body size, speed, direction, dwell, curvature, tap spacing, and reversal count.
6. Distinguish tap, double tap, long press, stroke, small repeated strokes, circular rub, and heart-like trace.
7. Apply a recognizer decision threshold with a clear 'ambiguous' outcome instead of forcing a wrong action.
8. Suppress accidental duplicate taps after a successful double tap.
9. Reject huge accidental drags, swipes outside the bear, offscreen drags, canceled pointers, and gestures interrupted by route changes.
10. Assign a bounded physical style: gentle, normal, or playful.
11. Generate a versioned, validated, compact semantic TouchIntent.
12. Clear temporary high-resolution pointer data unless explicit preview/editing still needs it.

Adaptive illustrative heuristics, to tune on devices:

- simple tap: brief contact and low normalized displacement;
- double tap: two short compatible contacts within a small time-and-distance window;
- press/hold: continuously contacted zone for several hundred milliseconds;
- stroke: meaningful displacement along a mostly coherent direction;
- circular rub: moderate curvature and directional wrap, avoiding false circles from tremor;
- quick repeated stroke: several short direction changes within one zone;
- trace: optional user-selected drawing mode, not arbitrary handwriting interpretation.

Build the recognizer so device DPI, safe areas, portrait/landscape layout, and accessibility font sizing do not change the semantic meaning. Use normalized geometry and adjustable sensitivity settings. Start with safe defaults; collect no analytics that expose full touch trajectories without explicit opt-in.

### 9. CORE TOUCH LIBRARY — TEN COMPLETE INTERACTIONS

Every row below needs distinct recognition, local reaction, sender-to-receiver choreography, appropriate intensity variants, release animation, and QA tests:

1. **Gentle Head Pet** — long downward/sideward stroke on head; eyes soften and close; head tilts into contact; ears lag; sender-bear paw traces a gentle arc along receiver's head.
2. **Nose Boop** — brief tap on nose; subtle fast head recoil, eye blink, torso recovery; sender paw targets receiver nose exactly; repeated boops have restrained variation.
3. **Cheek Caress** — stroke cheek; gentle blush and side tilt; sender paw makes cheek contact without obscuring eyes; receiver may look shy.
4. **Paw Hold** — deliberate hold on paw; paw lifts into user's direction; sender/receiver paws meet; contact persists for an authored duration; release is slow and meaningful.
5. **Belly Rub** — small circular motion over belly; contained playful squash and subtle body lean; do not have hand clipping through torso; nonsexual, wholesome cartoon reaction.
6. **Ear Rub** — gentle rub on ear; ear bends within art limits and springs back; receiver can lean into contact; avoid overextended stretching or identity distortion.
7. **Hug Hold** — long-press chest/hug zone; local bear extends both arms; remote pair performs a physically aligned real hug with near/far arms, correct squeeze, weight shift, and cozy release.
8. **Back Comfort** — slow stroke over accessible upper back/shoulder variant; shoulder tension relaxes, eyes soften; remote pair performs a comforting back rub with actual paw-to-back alignment.
9. **Heart Trace** — deliberate heart-like trace within a separate 'Draw a Heart' interaction; small glowing trace, gaze tracking, and soft chest landing; partner reveal may use magical trace rather than literal paw strokes.
10. **Tiny Tickle** — short rapid strokes over a small belly zone; playful squirm and temporary squash; no excessive flailing, unstable simulation, or dialogue/sound resembling speech.

Each touch should have three styles:

- Gentle: longer attack/release, small pose offsets, high damping, peaceful facial expression.
- Normal: responsive but moderate movement, clear contact, balanced recovery.
- Playful: slightly faster anticipation, larger but bounded animation amplitude, visibly bouncier ears/paws and richer reaction.

Intensity may be user-adjustable and can be inferred only from movement patterns—not merely force/pressure.

### 10. GESTURE STATE MACHINE AND CONFLICT MANAGEMENT

Use explicit states, approximately:

- idle;
- pointer_down;
- tracking;
- recognized;
- reacting_local;
- local_preview_ready;
- previewing;
- send_pending;
- send_succeeded;
- send_failed;
- receiving_envelope;
- opening;
- playing_remote;
- completed;
- replaying;
- canceled.

Define valid transitions and cancellation paths. A route pop, app background, pointer cancel, pair revocation, logout, or reduced-motion preference update must not leave held-down limbs or stuck physics. No sending until an explicit Send action. Do not allow multiple send requests from rapid double taps; use client-generated idempotency keys and pending UI guards.

Separate three concepts in code:

- TouchSample: transient high-fidelity local input, not for Firestore.
- TouchIntent: validated compact semantic description that can be saved/sent.
- TouchPlayback: deterministic render-time animation instructions and actual contact solver.

Include result types for recognized, ambiguous, invalid, canceled, and unsupported. No silent coercion of an invalid heart trace into a nose boop.

### 11. COMPACT PAYLOAD DESIGN AND DETERMINISTIC REPLAY

Illustrative schema, adapt it to actual existing models and collection conventions:

~~~json
{
  "schemaVersion": 1,
  "eventId": "client_uuid",
  "pairId": "pair_document_id",
  "senderUid": "sender_firebase_uid",
  "receiverUid": "receiver_firebase_uid",
  "kind": "touch_echo",
  "touchType": "head_pet",
  "touchZone": "head",
  "style": "gentle",
  "intensity": 0.35,
  "durationMs": 1800,
  "reactionVariant": "shy_soft",
  "animationId": "touch_head_pet",
  "animationVersion": 1,
  "physicsSeed": 82317,
  "normalizedTrace": [],
  "createdAt": "server_timestamp",
  "status": "unopened"
}
~~~

For a natural short stroke, do not needlessly transmit raw traces; semantic type, target zone, duration/style, variant, and a deterministic seed are usually sufficient. For heart drawing, optionally use a small **bounded, quantized, normalized** trace with a strict length cap. Coordinates must be in a coordinate system portable across body sizes and phones. Do not collect or store OS pointer hardware IDs, device fingerprints, or continuous motion telemetry.

Persist animationId plus animationVersion to replay old messages after future animation revisions. Never assume the newest animation file will preserve old timing or anchors exactly. Provide an authored fallback if a particular older asset version was removed.

Store one intent per completed send, not 60 write operations per second. Document writes and real-time listeners must be bounded. The receiver renders all 60 FPS physics locally. Validate payload size, numeric ranges, enum values, duration caps, trace count caps, maximum send rate, and allowed model assignments.

### 12. FIRESTORE ENVELOPE AND STRICT OPEN-TO-REVEAL

Build a generic inbox envelope separate from detailed touch data if necessary to prevent the ordinary UI from discovering gesture details before Open. One possible layout:

- pairings/{pairId}/touchEchoes/{eventId} — envelope, sender UID, receiver UID, createdAt, unread/open flags, generic preview.
- pairings/{pairId}/touchEchoes/{eventId}/private/payload — touch type, parameters, animation version, optional short trace, deterministic seed.

This is an illustrative structure, not a demand to discard the existing Firestore schema. Prefer a safe adapter to current inbox and pairing conventions.

Unopened inbox queries read only envelopes. The receiver's explicit Open action performs an authorized state transition; detailed payload is then read using an explicitly authorized reveal path. Security Rules can restrict payload reads based on receiver membership and appropriately recorded opened state, but a native client can never cryptographically prove a literal physical tap. Do not promise cryptographic 'tap proof'.

Define exact envelope states and timestamps:

- draft (local only);
- sending / queued locally;
- sent / delivered-to-database;
- unopened;
- opening;
- opened;
- playback_completed;
- failed / revoked where applicable.

Do not confuse notification delivery with the recipient having opened the animation. Define one canonical openedAt server timestamp. Separate playbackCompletedAt if desired. Do not change openedAt during Replay. Use idempotent update transactions where state verification matters. Firestore client transactions fail offline; handle this accurately rather than claiming an offline transition was committed.

The receiver's home screen should not eagerly prefetch private payloads to create visual spoilers. Once the receiver has opened it, an optional locally cached replay is acceptable under a sensible privacy policy.

### 13. FIREBASE AUTHORIZATION AND SECURITY RULES

Enforce membership server-side with actual Firebase Auth UIDs and the current pair membership source of truth. Require sender and receiver to be active members of the same pair, with mutually appropriate roles. Do not trust client-supplied pairId/senderUid merely because it arrived in a request. Explicitly validate allowed keys and immutable ownership fields.

Required policy:

1. Authenticated sender alone may create an outgoing Touch Echo for their paired receiver.
2. A stranger and former partner cannot read a pair's Echoes.
3. The sender cannot impersonate their receiver or write receiver-opened fields.
4. Recipient alone may mark their own Echo as opened/played, subject to valid transitions.
5. The sender and receiver cannot rewrite the original payload once accepted.
6. A revoked/unpaired relationship blocks new sends and new unauthorized reads as defined by the product's retention policy.
7. A user cannot create an Echo to themselves unless the existing product explicitly supports self-preview locally without a remote message.
8. Numeric payloads, enums, arrays, version bounds, and document sizes are validated.
9. Duplicate event IDs cannot overwrite unrelated existing events.
10. Test malicious updates of ownership fields, pair fields, timestamps, status, payload, and replay counts.

Use Firebase Local Emulator Suite and automated rules tests if configured or safely installable. Never deploy unreviewed permissive rules to production. Preserve unrelated established rules. Avoid overly broad catch-all authenticated-user permissions.

### 14. FIREBASE SPARK, PUSH, AND REAL-TIME EXPECTATIONS

Default to the no-cost Spark plan and the project's current eligible Firebase products. In-app Firestore listeners can update an open inbox while the app is running. Programmatic Firebase Cloud Messaging delivery generally requires a trusted sending environment; the mobile client must never send with embedded server/admin credentials. If no suitable trusted sender exists within the allowed project plan, ship reliable in-app inbox badges first, and report push as a separate backend decision.

Do not use Cloud Functions or scheduled functions without checking current plan requirements and explicitly noting any billing change. Do not silently introduce server-required features. The feature must function without remote AI inference and without video upload.

Build efficient listeners that only subscribe to the relevant paired user's inbox and detach on logout/unpair/navigation as appropriate. Bound pagination and memory-history reads. Use server timestamps and local pending indicators. Document the read/write pattern and likely Spark usage; do not guarantee zero cost if quotas or other product limits are exceeded.

### 15. OFFLINE FIRST AND CONNECTION LOSS

- Local Touch Mode and local physics work offline.
- Preview works offline using local animation assets.
- If user presses Send while offline, queue a validated local pending intent or use a safe supported Firestore offline-write path; display 'Pending' rather than 'Delivered'.
- Persist a safe client-generated event ID for retry/idempotency.
- On reconnect, reconcile the database acknowledgment and update delivery UI.
- Handle duplicate client retries and app restarts without duplicate inbox entries.
- Do not optimistically mark receiver-opened state while an offline transaction has not committed.
- If opening an unopened Echo requires current online authorization, show a warm 'Connect to open this touch' state instead of pretending it opened.
- Already-opened Echoes may be replayed from a safe local cache if privacy settings allow.
- If the pair is revoked before pending delivery, do not complete the send; resolve queued events according to product policy.
- Any failure should have a friendly retry and no sensitive debug details exposed in UI.

### 16. ANIMATION ARCHITECTURE — LIVE TWO-BEAR SCENE

Create or adapt a shared interaction scene containing:

- stage/camera coordinate mapper;
- receiver and sender rig controllers;
- animation state machine;
- pose/blend timeline;
- shared contact anchor resolver;
- constraints for paw-to-head, paw-to-paw, nose-to-nose, cheek, hug, and back contact;
- separate primary animation, corrective contact transforms, and secondary motion;
- depth ordering for near/far arms;
- expression transition controller;
- deterministic seeded secondary visual particles;
- timing and interruption coordinator;
- optional backdrop and UI choreography.

Animations must not be two unrelated canned clips played at the same time with guessed offsets. For each reveal, define shared scene roles, initial separation, approach, contact acquire, contact hold, contact release, return to idle. The sender can be brown or white depending on actual account pairing. Role reversal must never destroy asymmetric ear markings or facial designs.

If using Rive, Flame, custom Flutter painting, Spine, or another runtime, use what fits the actual existing code and licensed assets. Explain the choice. Avoid large dependencies unless necessary. If editable model artwork is unavailable, clearly delineate which animation and code phases require new artistic assets; do not fake full fidelity with scaling whole-body bitmaps.

### 17. PHYSICS — AUTHORING PLUS SPRINGS

The intended motion is **authored pose animation enhanced by stable spring secondary motion**, NOT a free rigid-body ragdoll. Animate purpose and emotional choreography with key poses, inbetweening, interpolation, physically coherent motion curves, and specific contact poses. Apply tuned secondary physics to ears, body settling, paws, plush compression, accessories, blanket edges, particles, and delayed head settling.

For custom spring degrees of freedom, a target-based damped oscillator can be expressed as:

acceleration = omega^2 * (target - displacement) - 2 * dampingRatio * omega * velocity.

Use a bounded fixed timestep, preferably 1/60 second, a bounded catch-up loop, and a stable integrator such as semi-implicit Euler. Decouple simulation from rendering where appropriate. Clamp invalid large dt on resume and bound overshoot/joint angles. Avoid perpetual oscillation. Use restrained near-critical settling for comforting touch and slightly underdamped ear lag for playful touch.

Stage coordinates and velocities must be normalized, not tuned only for one phone size. Maintain ground contacts. Contact constraints must be solved before secondary deviations can visibly separate paws from target anatomy. Clamp head angle, neck translation, shoulder reach, squash/stretch scale, ear bend, and torso displacement.

Example Head Pet:

1. Sender anticipates by looking at receiver.
2. Sender shifts weight and extends near-side arm.
3. Paw finds receiver head_top or head_center contact point.
4. On contact, receiver head tilts a controlled number of degrees toward the paw.
5. Receiver eyes soften or close; cheeks shift subtly; torso compresses.
6. Ear secondary motion lags the head turn.
7. Paw follows a short anatomically valid stroke without slipping through the skull.
8. Receiver holds a comfortable expression during the stroke.
9. Sender releases contact.
10. Receiver head and ears settle with appropriate springs.
11. Both return naturally to idle.

For Nose Boop, use faster anticipation and smaller deformation. For Paw Hold, maintain a stable common paw anchor during hold. For Hug Hold, use near/far arm layering and intentional squeeze/contact across both torsos. For Ear Rub, use local ear deformation only, without changing the whole face. For Heart Trace, use a separate luminous line effect and optional gaze tracking.

### 18. ANIMATION QUALITY AND VISUAL ART DIRECTION

The original bears are minimal, rounded, soft, cuddly characters. Preserve:

- gentle clean 2D art;
- small dark oval eyes;
- soft pink cheeks on white bear;
- caramel body and pale cream muzzle on brown bear;
- visually consistent dark outline weight;
- small short limbs;
- natural asymmetry from source drawings.

Use:

- carefully authored anticipation;
- slow-in/slow-out easing and custom animation curves;
- overshoot only where appealing;
- squash and stretch in moderation;
- blink and eyebrow/eye line if compatible with original art;
- head lean and gaze tracking;
- paw recoil and ear sway;
- hand-drawn corrective touch-ups for silhouette collisions;
- consistent shadows under standing characters;
- subtle heart particles, not confetti overload;
- optional restrained haptic feedback;
- expressive idle breathing without repetitive obvious looping.

Avoid:

- generic 3D emojis as model replacements;
- detached paws;
- extra arms;
- twisted heads;
- rigid robotic motions;
- constantly vibrating ears;
- head penetrating body;
- arm overlapping receiver's eyes incorrectly;
- spinning entire full-body image as a substitute for articulation;
- bright distracting UI particles covering the character.

### 19. DETAILED ANIMATION TIMELINES TO AUTHOR

**Head Pet:** gaze anticipation -> shoulder/paw reach -> soft top-head contact -> 1-3 slow strokes -> eyes relax, head lean -> stop -> paw release -> ear settling -> smile.

**Nose Boop:** brief attention shift -> fast paw approach -> tiny contact compression -> nose recoil -> quick blink -> soft spring rebound -> sender retracts paw -> shared look.

**Cheek Caress:** tender approach -> paw on outer cheek -> receiver blush/tilt -> sustained small movement -> shy eye movement -> release.

**Paw Hold:** both characters notice each other -> each reaches -> paws meet with physically correct near/far layering -> sustained quiet breathing -> small squeeze -> gradual release.

**Belly Rub:** sender leans close -> receiver opens torso space -> paw travels in short bounded circle -> subtle body squash, content reaction -> recovery without body intersections.

**Ear Rub:** contact with ear shape -> controlled ear bend -> receiver shifts head toward paw -> gentle lingering -> damped return.

**Hug Hold:** symmetric or complementary reach, foot shift, belly/chest compression, far arm behind receiver, near arm over torso, head rest, two gentle squeezes maximum, long breathing hold, graceful release.

**Back Comfort:** sender approaches side -> supportive paw lands at shoulder/back -> receiver's posture softens -> slow small shoulder rub -> brief reassuring hold -> release.

**Heart Trace:** normalized glowing heart path is traced -> both bears look toward the visual effect -> heart floats and touches receiver chest -> blush -> shared look -> fade.

**Tiny Tickle:** short paw motion -> receiver twists safely within pose constraints -> subtle happy bounce -> pause -> second smaller response -> settled release.

For each sequence, author contact poses for both bear roles, expressions, animation curves, durations, transition windows, reduced-motion alternative, accessibility semantics, and a clear finished frame. No gesture may remain a placeholder.

### 20. SPECIAL EFFECTS, SOUND, AND HAPTICS

Optional effects must remain subordinate to model acting:

- thin pink contact sparkle at correct contact anchor;
- soft heart pulse only when meaningful;
- subtle sparkles trailing a heart trace;
- small petting warmth/cheek blush;
- tiny grounded shadow response;
- receiver can disable extra effects;
- optional quiet nonvocal SFX only, if project already supports sound and user opts in;
- optional subtle device vibration for recognized touches, successful delivery, and soft hug squeeze if supported.

Haptics must be intensity-adjustable and respect OS accessibility and power settings. Do not add any speech audio or talking mouth animation. No sound is required for full enjoyment.

### 21. INBOX, TOUCH BACK, AND MEMORY FEATURES

Touch Back:

- receiver completes reveal and presses Touch Back;
- recipient returns to Touch Mode as their own bear;
- user performs a new valid touch;
- preview identifies the original Echo thread as the reply target;
- send creates a new immutable Echo with replyToEventId, preserving privacy checks;
- thread navigation displays a small chain of affection without becoming a chat feature.

Replay:

- reuses the original immutable TouchIntent and animation version;
- seeded particles and authored variation are repeatable where practical;
- does not generate extra network writes for each frame;
- does not reset openedAt;
- should work after later app resumes if asset version is compatible.

Save Memory:

- explicit opt-in to save a personal or shared memory;
- preserve type, date, animated scene reference, sender/receiver assignments, and optional selected scene thumbnail;
- avoid uploading large rendered videos;
- support Delete and controls about whether a saved memory is shared with partner;
- never reveal an unopened event through a memory preview.

### 22. SCREEN AND COMPONENT STRUCTURE

Add these using the existing state management/router instead of inventing a parallel app shell:

- TouchModeEntry / TouchModeScreen;
- TouchZoneOverlay (debug-only visualization toggled off in production);
- TouchInputController;
- TouchClassifier;
- TouchIntentPreview;
- SendTouchButton and SendStatusIndicator;
- GenericTouchEchoInboxCard;
- TouchEchoRevealScene;
- ReturnTouchAction;
- TouchMemoryCard;
- TouchSettingsPanel;
- NoNetwork / PairRevoked / MissingAsset / ReducedMotion fallback states.

The actual class/file names may be adapted to the current codebase. Each component should have clear responsibilities, accessibility semantics, loading states, disposal behavior, and test seams.

### 23. DART DOMAIN MODEL AND SERVICES

Create typed models and validators where absent:

- TouchZone enum;
- TouchGestureKind enum;
- TouchStyle enum;
- TouchIntensity (validated bounded value);
- TouchSample (ephemeral);
- TouchPathSummary;
- TouchIntent;
- TouchAnimationSpec / AnimationVersion;
- TouchEchoEnvelope;
- TouchEchoPayload;
- TouchEchoStatus;
- TouchEchoReply;
- TouchPlaybackSceneState;
- TouchPreferences.

Services/controllers:

- rig hit-test mapper;
- pointer tracker;
- gesture recognizer;
- touch classifier;
- local reaction director;
- two-bear contact coordinator;
- fixed-step secondary motion simulation;
- encode/decode/validation;
- paired-user authorization repository;
- Touch Echo create/reveal/reply/replay repository;
- inbox watch stream;
- safe retry/queue service;
- optional notification adapter (only if a secure sending backend exists);
- reduced-motion and haptics adapter.

Use testable dependency boundaries. No imperative Firestore writes buried directly inside character paint callbacks. Avoid global mutable singleton state that persists unintentionally across different users or pairings.

### 24. SECURITY AND DATA RESILIENCE TESTS

At minimum, automate:

- unauthenticated read/write denied;
- unrelated third account denied;
- wrong pair membership denied;
- self-spoofed sender UID denied;
- forged receiver UID denied;
- sender attempting to mark received event opened denied;
- receiver attempting to change sender, recipient, event type, intensity, or timestamp denied;
- malformed enum and out-of-bounds numeric data denied;
- huge normalized trace denied;
- valid sender creation succeeds;
- receiver opens valid envelope once;
- repeated Open does not modify original openedAt;
- revoked pairing behavior is enforced consistently;
- no reply can point at an unauthorized Echo;
- duplicate event ID cannot overwrite a prior event;
- opening state does not leak an unapproved preview;
- offline retry does not duplicate event;
- sender/receiver reversal produces correct scenes;
- login/logout switches streams safely.

If the project's exact security model cannot support a proposed security constraint without an additional trusted backend, explain the limit and present the best secure client-plus-rules implementation rather than weakening security quietly.

### 25. TOUCH RECOGNIZER TESTS

Use deterministic synthetic pointer sequences:

- slow head stroke;
- fast head swipe;
- single nose tap;
- correct double tap interval;
- tap too far apart to be double tap;
- press held then canceled by route change;
- long paw hold;
- intentional cheek stroke;
- belly circle clockwise;
- belly circle counter-clockwise;
- small unintentional tremor that should not be classified as circle;
- tiny tickle strokes;
- heart trace within explicit heart mode;
- heart-like scribble outside heart mode;
- movement across head/nose region boundary;
- multi-touch ambiguity;
- off-character starting point;
- sudden phone interruption;
- changed device DPI;
- portrait and landscape scene mapping;
- fast text-scale/accessibility mode.

Classifier tests should verify both predicted touch kind and false-positive suppression, not merely that recognizer callbacks execute.

### 26. ANIMATION VISUAL AND PHYSICS QA

Capture actual rendered frames or video test output at meaningful checkpoints:

- neutral start;
- anticipation;
- first contact;
- full held contact;
- reaction peak;
- contact release;
- 0.2 seconds after release;
- final settled pose.

For all ten touch types, check:

- white as sender and brown as receiver;
- brown as sender and white as receiver;
- small and large display sizes;
- 60 FPS target and intentional lower frame rate conditions;
- reduced-motion;
- rapid interruption and repeated playback;
- app background/resume;
- mirror/view orientation changes;
- correct ear marking and cheek/muzzle identity;
- no clipping;
- anchored paws;
- limits on deformation and joint bends;
- the last physics frame settles without indefinite jitter;
- expression returns to a valid idle or post-gesture state.

Where visual screenshot test infrastructure does not exist, add or propose the smallest practical harness and explicitly report which visual checks still need a human on-device review.

### 27. PERFORMANCE AND BATTERY BUDGET

- Aim for smooth 60 FPS where capable without promising every low-end device achieves it.
- Keep high-frequency pointer sampling local only; never cause every pointer move to trigger a Firestore write.
- Preload small commonly used animation assets.
- Avoid decoding large model sheets repeatedly.
- Dispose streams, timers, physics controllers, and input listeners properly.
- Reduce costly visual effects when device is struggling or reduced-motion enabled.
- Advance simulation only for visible scenes.
- Pause stable rigs when app is backgrounded.
- Avoid persistent notification polling; use proper scoped live subscriptions.
- Use performance profiling rather than guessing the cause of jank.

### 28. ACCESSIBILITY, CONSENT, AND WELLBEING

- No touching another person's character in a live session without both users opting in to that session.
- Async sends require explicit sender action and receiver reveal.
- Support notification mute, unwanted-touch block, and unpair.
- Use accessible labels for touch zones and equivalent buttons: 'Send gentle head pet', 'Send paw hold', etc.
- Motion reduction preserves emotional meaning with simpler fades/poses.
- Haptic on/off and intensity preference.
- Color alone never conveys delivery state.
- Targets meet mobile usability guidance.
- No unnecessary microphone, camera, or location permissions.
- No aggressive or harmful depictions; keep all bear interactions gentle, affectionate, and wholesome.
- Provide screen-reader alternative descriptions without turning characters into spoken conversational features.

### 29. USER STORIES AND BDD ACCEPTANCE SCENARIOS

Story 1 — Local interaction:

- Given I am signed in and my bear is idle,
- When I slowly stroke its head,
- Then my bear responds immediately with a matching head/eye/ear animation,
- And the completed input becomes a previewable 'Gentle Head Pet' intent.

Story 2 — Explicit send:

- Given a previewable TouchIntent,
- When I choose Send This Touch,
- Then one validated event is created for my authorized partner,
- And I see pending/delivered/failure status accurately.

Story 3 — Private unopened delivery:

- Given my partner sent an Echo,
- When I open my inbox,
- Then I see only a generic unopened envelope,
- And no touch animation autoplays or reveals the hidden gesture.

Story 4 — Partner deliberately opens:

- Given an unread Echo in my inbox,
- When I tap Open,
- Then the app authorizes and loads its payload,
- And sender/receiver models play the coordinated physical touch.

Story 5 — Touch Back:

- Given I have completed a received Echo,
- When I choose Touch Back and perform a different touch,
- Then the new reply is sent to the original sender with a valid reply reference.

Story 6 — Account security:

- Given I am authenticated but not a member of another pair,
- When I attempt to read, write, reveal, or modify their Echo,
- Then Firestore Security Rules deny the operation.

Story 7 — Offline:

- Given my device has no network,
- When I touch and press Send,
- Then I can preview locally and see Pending,
- And no UI claims it was delivered until the database acknowledges it.

Story 8 — Animation integrity:

- Given either bear is the sender,
- When a Head Pet or Hug Hold Echo is revealed,
- Then the actual paw contact aligns with the receiving rig,
- And both characters keep their original appearance without clipping.

Story 9 — Reduced motion:

- Given reduced motion is enabled,
- When an Echo is opened,
- Then the same affection is conveyed with simplified safe movement.

Story 10 — No talking:

- Given any Touch Echo mode or reveal screen,
- When it runs,
- Then it never requests microphone permission, generates character dialogue, voice, speech bubbles, or lip-sync.

### 30. PHASED IMPLEMENTATION — WORK IN THIS ORDER

**Phase 0: Audit and baseline**

- Inspect existing app, assets, Firebase, security, tests, and four reference images.
- Provide actual implementation map.
- Identify dependencies, blockers, migration/compatibility concerns.

**Phase 1: Model readiness**

- Repair layered rigs, hit zones, contact anchors, expressions, body-part pivots.
- Ensure white/brown identities remain stable.
- Add small visual debug overlay for touch zones and anchors.

**Phase 2: Touch engine**

- Build local pointer tracker, gesture classification, zone mapping, semantic TouchIntent.
- Implement Head Pet, Nose Boop, and Paw Hold as the first polished vertical slice.
- Add unit tests for positive and ambiguous recognitions.

**Phase 3: Physics and paired animation**

- Implement shared two-bear controller, contact solver, authored reveal choreography, damping and ear/paw follow-through.
- Test both sender/receiver permutations.

**Phase 4: Preview and send**

- Design Touch Mode, preview/replay, pending/success/error.
- Implement compact typed serialization, Firebase creation, idempotency and offline handling.

**Phase 5: Receiver reveal**

- Generic inbox envelope, restricted payload fetch, deliberate open, two-bear playback, replay, status updates.
- Add Firestore Security Rules and emulator tests.

**Phase 6: Touch Back**

- Link reply Echoes correctly; sender/receiver roles reverse; no unauthorized thread reference.

**Phase 7: Complete ten-touch library**

- Add Cheek Caress, Belly Rub, Ear Rub, Hug Hold, Back Comfort, Heart Trace, Tiny Tickle.
- Add gesture intensity and animation variants with visual QA.

**Phase 8: Memory, accessibility and polish**

- Favorite/replay/saved memory, haptic preferences, reduced motion, accessible alternatives, UI refinement.

**Phase 9: Regression and performance**

- Keep all 24 gestures intact; verify login/pairing/inbox; test Firebase rules; profile Flutter animation and memory; capture screenshots.

**Phase 10: Optional future Live Touch**

- Only after explicit user approval and asynchronous feature readiness.
- Both partners join voluntarily; event-based sync with disconnection recovery and no per-frame database writes.

### 31. DO NOT OVERCLAIM OR STOP AT SCAFFOLDING

Do not deliver a nearly empty UI with ten buttons and call Touch Echo done. Do not claim 'head pet complete' when the bear is an unrigged image with a simple scale tween. Do not fake Firebase delivery via local mock state when the user expects two authorized accounts. Do not consider tests passing sufficient proof that contact looks good.

At the end of each phase:

- summarize files changed;
- explain visible user-facing behavior;
- identify exact tests run and whether they passed;
- describe which physical animation contact points were visually inspected;
- list remaining incomplete work;
- keep the app compilable when possible.

If a dependency or asset is missing, ask a focused question while continuing safe implementation work.

### 32. REQUIRED FINAL HANDOFF

Deliver:

1. Summary of the complete user experience and what actually works.
2. Real files created and modified.
3. Character rig architecture and touch-zone diagram or documented anchor map.
4. Description of each of ten touch recognizers.
5. Pair-contact choreography and physical motion implementation.
6. Flutter integration and state management decisions.
7. Event/envelope/payload schema and animation version strategy.
8. Firebase Spark compatibility decisions and any optional features deferred.
9. Firestore rules and authorization test results.
10. Offline, retry and idempotency behavior.
11. Screenshots or frame captures of actual rendered Touch Mode, Preview, Inbox, Reveal, and Touch Back flows where available.
12. Manual device test instructions for two authorized devices/accounts.
13. Accessibility and reduced-motion review.
14. List of all successful and unsuccessful tool commands/tests.
15. Honest limitations and remaining work.

### 33. FINAL CREATIVE DIRECTION

Touch Echo should feel like **I touched my bear, and my partner felt the affection through our two animated bears**.

When I stroke the brown bear, it should lean into my finger as if it enjoys being petted. When I send that Echo, my partner's white bear must receive a believable, beautifully staged touch from the brown bear. The moment should be calm, warm, intimate in a wholesome way, artistically polished, and emotionally genuine.

The **single strongest recommendation** is to perfect a **contact-correct Head Pet vertical slice** with the complete pipeline—local finger stroke, classification, physically reactive sender bear, preview, authorized Firebase send, generic unopened inbox envelope, deliberate open, two-bear contact animation, Touch Back, and replay—before implementing the other nine touch types or any live synchronous feature.

Use the accompanying four reference pictures wherever actually accessible. Maintain original character identity. Use physically coherent 2D rigs, authored anticipation and contact poses, meaningful secondary springs, accurate partner roles, honest app state, secure Firebase, and beautiful Flutter UX.

**Do not add talking features. Implement the actual feature in the existing project, verify its behavior, and report evidence of completion.**
