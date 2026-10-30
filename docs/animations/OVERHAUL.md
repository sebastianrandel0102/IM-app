# Bear animation implementation — 2026-10-31

All 24 catalog IDs, names, categories and delivery meanings are preserved. The
runtime implementation is editable Flutter vector animation. No Rive artboard,
mesh, bone weights or binary asset has been edited: none was supplied. The
separate [Rive authoring contract](AUTHORING.md) remains an external deliverable.

## Audit and scope

The original `bear_scene.dart` contained all character paths and a repeating
sine-wave contact calculation. It grouped distinct gestures by `scene` string:
the three everyday kiss actions shared one lean, high five shared the hand
pose, comfort hug shared warm hug, and both sleep actions used standing bears
behind a blanket. Piggyback used a fixed offset without mounting; flower,
heart, umbrella and box were mostly fixed props. Blinking, contact and sway
were tied to the same repeating clock. The player used an unrelated 6/8/10-second
completion timer, including while the application was in the background.

Original raster timelines were exported before changing the renderer. Files in
`artifacts/animations/original/` and `refined/` show every gesture at normalized
times .04, .22, .40, .54, .72 and .96, in both brown-to-white and white-to-brown
roles. `original-renderer.dart.txt` preserves the source used for comparison.

Authentication, pairing, Firestore delivery/reveal, memories, settings storage,
navigation and Firebase rules were not changed. No dependency was added. No
backend resources were created or deployed. The implementation uses the same
Spark-compatible app services and the same original colors, head paths, ears,
muzzle, tiny facial features and outline widths.

## Runtime and editable source

| File | Responsibility |
| --- | --- |
| `lib/features/animation/presentation/bear_choreography.dart` | All 24 timelines, contact anchors, pose interpolation, reactions and playback state |
| `lib/features/animation/presentation/bear_vector_rig.dart` | Torso, rigid head, ear pivots, legs, bounded arm chains and corrective profiles |
| `lib/features/animation/presentation/bear_scene.dart` | Painting, props, blankets, local effects, ticker ownership and lifecycle suspension |
| `lib/features/animation/presentation/player_screen.dart` | Accessible input, replay, contact haptics, completion persistence and audio cleanup |
| `tool/animation_review.dart` | Local-only full-speed/quarter-speed review and frame scrubbing |
| `test/animation_test.dart` | Timeline, reach/contact, role reversal, reduced motion and lifecycle tests |
| `test/animation_player_test.dart` | Actual player holds, cancellation, tap debounce, Stop, wake and walking controls |
| `test/animation_visual_test.dart` | Reproducible Flutter raster contact sheets |

The rig hierarchy is `Root → Torso → Head → Ears/Face/Accessory`, with hip/leg
pivots and separate shoulder/elbow/paw chains. Torso scale is volume compensated
with reciprocal horizontal scale. Head and face transforms undo that scale;
eyes, muzzle and ears therefore do not stretch with a landing or hug. Arm reach
is bounded at 64 logical pixels with 32-pixel links and a curved elbow drawing.
`BearVectorRig.paw` exposes the actual bounded endpoint for tests, rather than
claiming an unreachable target is a contact. Small sitting feet and kiss
profiles are corrective vector drawings. There is no vertex mesh in this rig.

Character-relative cheek, forehead, nose, paws, shoulder, torso, hug, seat and
back anchors use the exact drawing transforms, including facing, breathing,
head turn, sitting and body rotation. The back anchor attaches the rider to
the carrier. Return kisses and every third boop mirror the acting poses while
keeping each colored actor on its existing side. Time always moves forward.

The phases are idle, attention, anticipation, approach, contact, reaction,
hold, recovery and complete. Most tracks have breakdowns at .08, .16, .22,
.34, .43, .46, .52, .60, .68, .78, .92 and .98, with action-specific overrides.
Position/rotation tracks use bounded cubic ease-in/ease-out; cozy and comfort
approaches use `(0.45, 0, 0.30, 1)`, ordinary approaches `(0.42, 0, 0.18, 1)`.
Heart flight and the coordinated turn use sine easing. Impact settling uses
`sin(65x) × exp(-19x)` with small bounded amplitudes. Retargeting blends from
the current pose over 280 ms; turn blending takes the shortest angular route.
No blanket/box-lid/touch target teleports between binary states.

Hold is supported for warm hug, comfort hug and cuddle. It stops progression
at .64 while independent breath/ear/arm motion remains alive; release continues
through recovery. Completion is emitted once by playback, with no independent
wall timer. Stop/wake blends to neutral. Replay constructs a fresh playback
instance. Pausing the app or disabling `TickerMode` stops elapsed action time,
and disposal removes the ticker and observer. Completed reduced-motion scenes stop requesting frames after their input/recovery transitions settle. Audio is stopped on background,
replay and Stop. Contact haptics are discrete and honor existing preferences.

The player keeps a large opaque touch target and equivalent buttons. Taps are
debounced for 250 ms and ignored during an active hold. Walk inputs are clamped
to ±25 and eased toward their target. The step loop depends on movement toward
that target, so feet settle when walking stops. A completed hand-hold remains
joined; a completed piggyback remains attached for further walking.

Reduced motion removes secondary oscillation, repeated stepping, spinning,
moving rain and decorative effects while retaining action poses, contact,
reactions, buttons and completion. Catalog thumbnails use a static .54 pose;
the player still advances a restrained timeline and completes normally.

## Corrections made during frame review

- Original large heads were intersecting during hugs. Outward neck offsets
  allow the short bodies and arms to come closer while keeping head shapes.
- Near-arm drawing is masked against its own rigid head. Idle arms stay under
  the face; a contact paw can still reach the other actor. The blowing-kiss paw
  has a small explicit foreground corrective drawing at its muzzle.
- Forehead-kiss horizontal contact is reached by moving the torso/root, so the
  head stays attached to the body. Resting is applied before goodnight contact
  is solved; the automated test caught and removed an 11.7-pixel offset.
- The carrier crouches before mounting. Rider offsets/tilt keep its face above
  the carrier and inside the canvas. Depth ordering puts the rider behind the
  carrier, with the attachment paw in front.
- The gift lid follows a continuous rising/rotating path and does not reclose
  when tapped after opening. Flower bloom persists after the tap pulse.
- Sleep breathing uses different frequencies/phases, with a curved blanket
  edge. Rain time remains fixed when reduced motion is enabled.

## Performance and review

One ticker drives a `ChangeNotifier` supplied directly to `CustomPainter`.
Animation ticks repaint without rebuilding the app's widget tree. The scene
has a `RepaintBoundary`, no mesh simulation, no unbounded particle emitter,
and at most four tiny cross sparkles per effect. An even-odd head mask avoids
per-frame path boolean operations. These are design measures, not a measured
60-FPS certification. Ordinary Android GPU/frame-time profiling and physical
two-device acceptance are still required; no Android device was connected.

Flutter references used during implementation: [CustomPainter repaint](https://api.flutter.dev/flutter/rendering/CustomPainter-class.html)
and [Ticker timing/muting](https://api.flutter.dev/flutter/scheduler/Ticker-class.html).

Run the local review workbench without Firebase:

```powershell
flutter run -t tool/animation_review.dart -d chrome
```

Select any action and sender color, use 1x/0.25x, pause/scrub the timeline,
then check Hold, Tap/react, reduced motion and the walking slider. This is a
development entry point, not a new application route or a replacement player.

```powershell
flutter analyze
flutter test
flutter test test/animation_visual_test.dart
flutter build apk --release
```

The automated timeline check samples each full action at 120 Hz with normal
and reduced motion, checks finite in-bounds anchors, per-frame displacement
and maximum limb reach. Additional tests check actual contact endpoints,
forward return affection, animated holds, completion-once, pause/resume,
route ticker suspension, retargeting, Stop, small layouts and controller
disposal. Both color roles render at 240 × 220. Raster review samples six
poses per action/role; it is not a claim that every rendered frame has been
manually approved on a physical device. See [QA record](QA.md) for final results.

## Per-gesture implementation record

All entries below refer to the four runtime source files listed above as the
**actual modified assets** (the latter two integrate every gesture). No `.riv`
file was modified. For every entry, the shared rig/reduced-motion/performance
notes above apply. The result recorded per entry means the automated 120-Hz
timeline/layout checks and sampled raster review; it does not mean Android
GPU profiling or external Rive source authoring was performed.

### 1. Warm Hug

- **Category:** Everyday
- **Original animation problems:** Repeated sine contact; large heads overlap; held pose could freeze or complete on a timer.
- **New key poses:** Notice ? small steps ? welcome paws ? torso contact ? squeeze ? breathing hold ? gradual separation.
- **Inbetweening improvements:** Separate continuous root, head, paw, eye and reaction tracks connect the listed breakdown poses; direction changes ease through their authored windows.
- **Interpolation curve changes:** Soft approach and bounded damped squeeze; 280-ms release retargeting.
- **Rig/deformer corrections:** Outward neck offsets and reciprocal torso scale; paws meet the opposite torso.
- **Secondary motion added:** Offset breathing, delayed ears and restrained shared sway.
- **Juicing added:** 2?3% contact compression and one contact haptic.
- **Frame-by-frame corrections:** Sampled contact/recovery poses reviewed in both color roles; shared own-head arm mask and original-outline preservation apply. Outward neck offsets and reciprocal torso scale; paws meet the opposite torso.
- **Interaction timing:** 7.2 seconds in gentle mode; shy ?1.15, playful ?0.88. Held contact extends the timeline where supported.
- **User gesture controls:** Hold/release, long-press cancellation or accessible Stay/Let go.
- **Expected emotional effect:** Affectionate welcome and mutual response.
- **Performance notes:** One shared vector rig/ticker per visible scene; bounded effects and no external mesh. Device GPU timing remains unmeasured.
- **Testing result:** Full 120-Hz timeline/anchor/reach checks and 240?220 rendering in both color roles passed. Six-pose raster review performed; device acceptance remains pending.
- **Actual modified assets:** bear_choreography.dart, bear_vector_rig.dart, bear_scene.dart and player_screen.dart (paths in the source table).
- **Unresolved limitations:** Shared 2D hug silhouette; no external wrap-around mesh. Editable Rive source and physical Android verification remain external/pending.

### 2. Cheek Kiss

- **Category:** Everyday
- **Original animation problems:** Same generic kiss lean as forehead/blowing kisses; no precise muzzle or receiver reaction.
- **New key poses:** Look ? shy tilt ? profile approach ? cheek contact ? surprise/blink ? blush ? retreat.
- **Inbetweening improvements:** Separate continuous root, head, paw, eye and reaction tracks connect the listed breakdown poses; direction changes ease through their authored windows.
- **Interpolation curve changes:** Separate head/torso tracks and a short eased contact hold.
- **Rig/deformer corrections:** Rigid profile drawing plus root/nose-to-cheek solve; cheek width compresses locally.
- **Secondary motion added:** Ear settling and independent blink/blush transitions.
- **Juicing added:** One small heart at contact and a discrete haptic.
- **Frame-by-frame corrections:** Sampled contact/recovery poses reviewed in both color roles; shared own-head arm mask and original-outline preservation apply. Rigid profile drawing plus root/nose-to-cheek solve; cheek width compresses locally.
- **Interaction timing:** 7.2 seconds in gentle mode; shy ?1.15, playful ?0.88. Held contact extends the timeline where supported.
- **User gesture controls:** Tap/Kiss back plays forward with reversed acting roles.
- **Expected emotional effect:** A shy affectionate exchange.
- **Performance notes:** One shared vector rig/ticker per visible scene; bounded effects and no external mesh. Device GPU timing remains unmeasured.
- **Testing result:** Full 120-Hz timeline/anchor/reach checks and 240?220 rendering in both color roles passed. Six-pose raster review performed; device acceptance remains pending.
- **Actual modified assets:** bear_choreography.dart, bear_vector_rig.dart, bear_scene.dart and player_screen.dart (paths in the source table).
- **Unresolved limitations:** Profile is a corrective vector shape, not a newly authored Rive view. Editable Rive source and physical Android verification remain external/pending.

### 3. Forehead Kiss

- **Category:** Everyday
- **Original animation problems:** Shared cheek-kiss lean never targeted a forehead.
- **New key poses:** Attention ? approach ? recipient bows ? sender lifts/tilts ? forehead contact ? eyes close ? soft retreat.
- **Inbetweening improvements:** Separate continuous root, head, paw, eye and reaction tracks connect the listed breakdown poses; direction changes ease through their authored windows.
- **Interpolation curve changes:** Long gentle head arc, bounded cubic contact and recovery.
- **Rig/deformer corrections:** Root moves with the head; forehead anchor is solved after recipient posture.
- **Secondary motion added:** Breath and delayed ear relaxation.
- **Juicing added:** Small contact heart without playful bounce.
- **Frame-by-frame corrections:** Sampled contact/recovery poses reviewed in both color roles; shared own-head arm mask and original-outline preservation apply. Root moves with the head; forehead anchor is solved after recipient posture.
- **Interaction timing:** 7.2 seconds in gentle mode; shy ?1.15, playful ?0.88. Held contact extends the timeline where supported.
- **User gesture controls:** Tap for a fresh forward kiss.
- **Expected emotional effect:** Quiet reassurance.
- **Performance notes:** One shared vector rig/ticker per visible scene; bounded effects and no external mesh. Device GPU timing remains unmeasured.
- **Testing result:** Full 120-Hz timeline/anchor/reach checks and 240?220 rendering in both color roles passed. Six-pose raster review performed; device acceptance remains pending.
- **Actual modified assets:** bear_choreography.dart, bear_vector_rig.dart, bear_scene.dart and player_screen.dart (paths in the source table).
- **Unresolved limitations:** The vector rig uses a bowed recipient rather than a separate side-view asset. Editable Rive source and physical Android verification remain external/pending.

### 4. Hold Hands

- **Category:** Everyday
- **Original animation problems:** Raised arms were not constrained to a common target; no actual walk cycle.
- **New key poses:** Look ? sender reach ? recipient reach ? joined paws ? optional synchronized steps ? settled joined pose.
- **Inbetweening improvements:** Separate continuous root, head, paw, eye and reaction tracks connect the listed breakdown poses; direction changes ease through their authored windows.
- **Interpolation curve changes:** Dedicated reach cubic and exponentially smoothed walk target.
- **Rig/deformer corrections:** Both bounded paw endpoints share one world target during movement.
- **Secondary motion added:** Opposed foot phases and small grounded weight transfer.
- **Juicing added:** No decorative burst; stable contact carries the action.
- **Frame-by-frame corrections:** Sampled contact/recovery poses reviewed in both color roles; shared own-head arm mask and original-outline preservation apply. Both bounded paw endpoints share one world target during movement.
- **Interaction timing:** 7.2 seconds in gentle mode; shy ?1.15, playful ?0.88. Held contact extends the timeline where supported.
- **User gesture controls:** Swipe or accessible left/right buttons, bounded ?25.
- **Expected emotional effect:** Togetherness and a steady connection.
- **Performance notes:** One shared vector rig/ticker per visible scene; bounded effects and no external mesh. Device GPU timing remains unmeasured.
- **Testing result:** Full 120-Hz timeline/anchor/reach checks and 240?220 rendering in both color roles passed. Six-pose raster review performed; device acceptance remains pending.
- **Actual modified assets:** bear_choreography.dart, bear_vector_rig.dart, bear_scene.dart and player_screen.dart (paths in the source table).
- **Unresolved limitations:** Walking stays within the existing small stage. Editable Rive source and physical Android verification remain external/pending.

### 5. Blowing Kisses

- **Category:** Everyday
- **Original animation problems:** Only the common body kiss lean and ambient hearts.
- **New key poses:** Paw to muzzle ? eyes close ? release ? curved heart flight ? cheek landing ? recipient blink.
- **Inbetweening improvements:** Separate continuous root, head, paw, eye and reaction tracks connect the listed breakdown poses; direction changes ease through their authored windows.
- **Interpolation curve changes:** Sine-eased flight with a sinusoidal vertical arc and eased catch input.
- **Rig/deformer corrections:** Muzzle/cheek anchors; explicit small foreground muzzle paw correction.
- **Secondary motion added:** Head tilt and follow-through; recipient follows the flight.
- **Juicing added:** One bounded traveling heart, not a particle emitter.
- **Frame-by-frame corrections:** Sampled contact/recovery poses reviewed in both color roles; shared own-head arm mask and original-outline preservation apply. Muzzle/cheek anchors; explicit small foreground muzzle paw correction.
- **Interaction timing:** 7.2 seconds in gentle mode; shy ?1.15, playful ?0.88. Held contact extends the timeline where supported.
- **User gesture controls:** Tap catches the heart; accessible Kiss back control preserves the existing label.
- **Expected emotional effect:** Playful distant affection.
- **Performance notes:** One shared vector rig/ticker per visible scene; bounded effects and no external mesh. Device GPU timing remains unmeasured.
- **Testing result:** Full 120-Hz timeline/anchor/reach checks and 240?220 rendering in both color roles passed. Six-pose raster review performed; device acceptance remains pending.
- **Actual modified assets:** bear_choreography.dart, bear_vector_rig.dart, bear_scene.dart and player_screen.dart (paths in the source table).
- **Unresolved limitations:** The existing generic kiss button label is retained; catch motion is action-specific. Editable Rive source and physical Android verification remain external/pending.

### 6. Good Morning

- **Category:** Everyday
- **Original animation problems:** Standing bears; a sun appeared only after a binary tap.
- **New key poses:** Sleeping breath ? approach/touch ? stir ? eyes open ? both paws stretch ? smile.
- **Inbetweening improvements:** Separate continuous root, head, paw, eye and reaction tracks connect the listed breakdown poses; direction changes ease through their authored windows.
- **Interpolation curve changes:** Wake and stretch overlap with separate eye opening.
- **Rig/deformer corrections:** Rigid head, raised arm chains and ?2.5% temporary torso stretch.
- **Secondary motion added:** Independent sleep breath and waking ears.
- **Juicing added:** Sun grows in smoothly; tap can advance waking.
- **Frame-by-frame corrections:** Sampled contact/recovery poses reviewed in both color roles; shared own-head arm mask and original-outline preservation apply. Rigid head, raised arm chains and ?2.5% temporary torso stretch.
- **Interaction timing:** 7.2 seconds in gentle mode; shy ?1.15, playful ?0.88. Held contact extends the timeline where supported.
- **User gesture controls:** Tap the sun/scene or the accessible action button.
- **Expected emotional effect:** A gentle happy greeting.
- **Performance notes:** One shared vector rig/ticker per visible scene; bounded effects and no external mesh. Device GPU timing remains unmeasured.
- **Testing result:** Full 120-Hz timeline/anchor/reach checks and 240?220 rendering in both color roles passed. Six-pose raster review performed; device acceptance remains pending.
- **Actual modified assets:** bear_choreography.dart, bear_vector_rig.dart, bear_scene.dart and player_screen.dart (paths in the source table).
- **Unresolved limitations:** Lighting uses the existing vector room palette. Editable Rive source and physical Android verification remain external/pending.

### 7. Head Pats

- **Category:** Playful
- **Original animation problems:** Generic raised arm did not reach the top of the head.
- **New key poses:** Shoulder raise ? recipient lowers head ? three soft rhythmic contacts ? ears settle ? paw lowers.
- **Inbetweening improvements:** Separate continuous root, head, paw, eye and reaction tracks connect the listed breakdown poses; direction changes ease through their authored windows.
- **Interpolation curve changes:** Cubic reach plus bounded short pat arcs and damped ears.
- **Rig/deformer corrections:** Crouched recipient keeps the forehead within the short arm reach.
- **Secondary motion added:** Delayed ear response and eye closing.
- **Juicing added:** Small contact response rather than a full-body bounce.
- **Frame-by-frame corrections:** Sampled contact/recovery poses reviewed in both color roles; shared own-head arm mask and original-outline preservation apply. Crouched recipient keeps the forehead within the short arm reach.
- **Interaction timing:** 5.8 seconds in gentle mode; shy ?1.15, playful ?0.88. Held contact extends the timeline where supported.
- **User gesture controls:** Tap repeats the forward pat sequence.
- **Expected emotional effect:** Patient approval and contentment.
- **Performance notes:** One shared vector rig/ticker per visible scene; bounded effects and no external mesh. Device GPU timing remains unmeasured.
- **Testing result:** Full 120-Hz timeline/anchor/reach checks and 240?220 rendering in both color roles passed. Six-pose raster review performed; device acceptance remains pending.
- **Actual modified assets:** bear_choreography.dart, bear_vector_rig.dart, bear_scene.dart and player_screen.dart (paths in the source table).
- **Unresolved limitations:** Pat arcs are procedural vector key poses, not individual external drawings. Editable Rive source and physical Android verification remain external/pending.

### 8. Nose Boop

- **Category:** Playful
- **Original animation problems:** No actual paw-to-nose alignment; taps changed only a text label.
- **New key poses:** Notice ? paw anticipation ? profile nose touch ? surprise ? settle ? retract.
- **Inbetweening improvements:** Separate continuous root, head, paw, eye and reaction tracks connect the listed breakdown poses; direction changes ease through their authored windows.
- **Interpolation curve changes:** Short eased reach, compact contact and damped recovery.
- **Rig/deformer corrections:** Profile nose target and bounded actual paw endpoint.
- **Secondary motion added:** Ear follow-through and surprise-to-smile eyes.
- **Juicing added:** Local reaction and discrete contact haptic.
- **Frame-by-frame corrections:** Sampled contact/recovery poses reviewed in both color roles; shared own-head arm mask and original-outline preservation apply. Profile nose target and bounded actual paw endpoint.
- **Interaction timing:** 4.4 seconds in gentle mode; shy ?1.15, playful ?0.88. Held contact extends the timeline where supported.
- **User gesture controls:** Tap repeats; every third tap reverses acting roles.
- **Expected emotional effect:** Tiny playful surprise.
- **Performance notes:** One shared vector rig/ticker per visible scene; bounded effects and no external mesh. Device GPU timing remains unmeasured.
- **Testing result:** Full 120-Hz timeline/anchor/reach checks and 240?220 rendering in both color roles passed. Six-pose raster review performed; device acceptance remains pending.
- **Actual modified assets:** bear_choreography.dart, bear_vector_rig.dart, bear_scene.dart and player_screen.dart (paths in the source table).
- **Unresolved limitations:** No exaggerated muzzle scaling or camera shake. Editable Rive source and physical Android verification remain external/pending.

### 9. Happy Dance

- **Category:** Playful
- **Original animation problems:** Both bears only swayed vertically; feet stayed static.
- **New key poses:** Invitation ? left weight shift ? step ? opposing paw swing ? hop ? right shift ? settle.
- **Inbetweening improvements:** Separate continuous root, head, paw, eye and reaction tracks connect the listed breakdown poses; direction changes ease through their authored windows.
- **Interpolation curve changes:** Rhythmic phase tracks with a delayed follower and eased envelope.
- **Rig/deformer corrections:** Hip pivots, articulated feet and rigid counter-tilting heads.
- **Secondary motion added:** Paws and ears lag the torso beat.
- **Juicing added:** Bounded hop/2.5% squash, without continuous impacts.
- **Frame-by-frame corrections:** Sampled contact/recovery poses reviewed in both color roles; shared own-head arm mask and original-outline preservation apply. Hip pivots, articulated feet and rigid counter-tilting heads.
- **Interaction timing:** 6.4 seconds in gentle mode; shy ?1.15, playful ?0.88. Held contact extends the timeline where supported.
- **User gesture controls:** Tap changes the beat/step sequence.
- **Expected emotional effect:** Shared playful energy.
- **Performance notes:** One shared vector rig/ticker per visible scene; bounded effects and no external mesh. Device GPU timing remains unmeasured.
- **Testing result:** Full 120-Hz timeline/anchor/reach checks and 240?220 rendering in both color roles passed. Six-pose raster review performed; device acceptance remains pending.
- **Actual modified assets:** bear_choreography.dart, bear_vector_rig.dart, bear_scene.dart and player_screen.dart (paths in the source table).
- **Unresolved limitations:** The internal beat is visual; it is not synchronized to a new music track. Editable Rive source and physical Android verification remain external/pending.

### 10. Piggyback Ride

- **Category:** Playful
- **Original animation problems:** Rider appeared at a fixed offset with no crouch, climb or attachment.
- **New key poses:** Carrier crouches ? rider approaches/climbs ? back attachment ? carrier rises ? rider settles ? walking.
- **Inbetweening improvements:** Separate continuous root, head, paw, eye and reaction tracks connect the listed breakdown poses; direction changes ease through their authored windows.
- **Interpolation curve changes:** Cubic mount and exponentially eased bounded walking.
- **Rig/deformer corrections:** Back anchor, support paw, rider tilt and corrected foreground/background order.
- **Secondary motion added:** Rider ears lag the carrier; both foot phases follow locomotion.
- **Juicing added:** Weight compression stays below 3.5%.
- **Frame-by-frame corrections:** Sampled contact/recovery poses reviewed in both color roles; shared own-head arm mask and original-outline preservation apply. Back anchor, support paw, rider tilt and corrected foreground/background order.
- **Interaction timing:** 7.2 seconds in gentle mode; shy ?1.15, playful ?0.88. Held contact extends the timeline where supported.
- **User gesture controls:** Swipe or left/right controls; mounted final pose supports further walking.
- **Expected emotional effect:** Trust and a little adventure.
- **Performance notes:** One shared vector rig/ticker per visible scene; bounded effects and no external mesh. Device GPU timing remains unmeasured.
- **Testing result:** Full 120-Hz timeline/anchor/reach checks and 240?220 rendering in both color roles passed. Six-pose raster review performed; device acceptance remains pending.
- **Actual modified assets:** bear_choreography.dart, bear_vector_rig.dart, bear_scene.dart and player_screen.dart (paths in the source table).
- **Unresolved limitations:** Layered 2D overlap is intentional; no independent external back-view mesh exists. Editable Rive source and physical Android verification remain external/pending.

### 11. Tiny Tickles

- **Category:** Playful
- **Original animation problems:** Reused the hug pose plus a text label; Stop cut straight to neutral.
- **New key poses:** Playful reach ? belly paw contact ? asymmetric wiggle ? laughing eyes ? soften/withdraw.
- **Inbetweening improvements:** Separate continuous root, head, paw, eye and reaction tracks connect the listed breakdown poses; direction changes ease through their authored windows.
- **Interpolation curve changes:** Two bounded, nonidentical rhythmic tracks and 280-ms Stop blending.
- **Rig/deformer corrections:** Torso target and isolated head counter-rotation.
- **Secondary motion added:** Small ear and head overlaps.
- **Juicing added:** Local laughter posture without whole-scene shaking.
- **Frame-by-frame corrections:** Sampled contact/recovery poses reviewed in both color roles; shared own-head arm mask and original-outline preservation apply. Torso target and isolated head counter-rotation.
- **Interaction timing:** 7.2 seconds in gentle mode; shy ?1.15, playful ?0.88. Held contact extends the timeline where supported.
- **User gesture controls:** Tap repeats; Stop cancels immediately and settles.
- **Expected emotional effect:** Light, controllable play.
- **Performance notes:** One shared vector rig/ticker per visible scene; bounded effects and no external mesh. Device GPU timing remains unmeasured.
- **Testing result:** Full 120-Hz timeline/anchor/reach checks and 240?220 rendering in both color roles passed. Six-pose raster review performed; device acceptance remains pending.
- **Actual modified assets:** bear_choreography.dart, bear_vector_rig.dart, bear_scene.dart and player_screen.dart (paths in the source table).
- **Unresolved limitations:** No new laugh recording or text particle system was added. Editable Rive source and physical Android verification remain external/pending.

### 12. High Five

- **Category:** Playful
- **Original animation problems:** Reused hand-holding arms; paws were not synchronized.
- **New key poses:** Raise ? approach ? common elevated target ? brief impact ? rebound ? lower paws.
- **Inbetweening improvements:** Separate continuous root, head, paw, eye and reaction tracks connect the listed breakdown poses; direction changes ease through their authored windows.
- **Interpolation curve changes:** Short reach envelope, damped impact and explicit early rebound.
- **Rig/deformer corrections:** Both actual bounded paw endpoints meet at (200,166).
- **Secondary motion added:** Head/ear follow-through after contact.
- **Juicing added:** At most four sparkle strokes and one light haptic; no screen shake.
- **Frame-by-frame corrections:** Sampled contact/recovery poses reviewed in both color roles; shared own-head arm mask and original-outline preservation apply. Both actual bounded paw endpoints meet at (200,166).
- **Interaction timing:** 4.8 seconds in gentle mode; shy ?1.15, playful ?0.88. Held contact extends the timeline where supported.
- **User gesture controls:** Tap repeats the contact sequence.
- **Expected emotional effect:** A clear shared celebration.
- **Performance notes:** One shared vector rig/ticker per visible scene; bounded effects and no external mesh. Device GPU timing remains unmeasured.
- **Testing result:** Full 120-Hz timeline/anchor/reach checks and 240?220 rendering in both color roles passed. Six-pose raster review performed; device acceptance remains pending.
- **Actual modified assets:** bear_choreography.dart, bear_vector_rig.dart, bear_scene.dart and player_screen.dart (paths in the source table).
- **Unresolved limitations:** Timing precision is expressed in the animation; the app does not score taps. Editable Rive source and physical Android verification remain external/pending.

### 13. Spinning Hug

- **Category:** Playful
- **Original animation problems:** Reused a normal hug with no coordinated turn.
- **New key poses:** Approach ? embrace ? shared pivot turn ? angular deceleration ? settle/release.
- **Inbetweening improvements:** Separate continuous root, head, paw, eye and reaction tracks connect the listed breakdown poses; direction changes ease through their authored windows.
- **Interpolation curve changes:** Sine-eased full turn; shortest-angle blending on replay/input.
- **Rig/deformer corrections:** Both bears and their arms share one pivot; uniform framing keeps them in bounds.
- **Secondary motion added:** Ears and step accents follow the turn.
- **Juicing added:** A single controlled 2D turn; reduced motion keeps the embrace.
- **Frame-by-frame corrections:** Sampled contact/recovery poses reviewed in both color roles; shared own-head arm mask and original-outline preservation apply. Both bears and their arms share one pivot; uniform framing keeps them in bounds.
- **Interaction timing:** 7.2 seconds in gentle mode; shy ?1.15, playful ?0.88. Held contact extends the timeline where supported.
- **User gesture controls:** Tap requests another forward turn; Replay restarts.
- **Expected emotional effect:** A delighted twirl together.
- **Performance notes:** One shared vector rig/ticker per visible scene; bounded effects and no external mesh. Device GPU timing remains unmeasured.
- **Testing result:** Full 120-Hz timeline/anchor/reach checks and 240?220 rendering in both color roles passed. Six-pose raster review performed; device acceptance remains pending.
- **Actual modified assets:** bear_choreography.dart, bear_vector_rig.dart, bear_scene.dart and player_screen.dart (paths in the source table).
- **Unresolved limitations:** This is a flat 2D shared-pivot turn, not a 3D orbit or new side/back artwork. Editable Rive source and physical Android verification remain external/pending.

### 14. Cuddle Time

- **Category:** Cozy
- **Original animation problems:** Generic hug above a static couch; blanket toggled instantly.
- **New key poses:** Sit ? look ? move closer ? arm contact ? eyes soften ? breathing hold ? settled seated pose.
- **Inbetweening improvements:** Separate continuous root, head, paw, eye and reaction tracks connect the listed breakdown poses; direction changes ease through their authored windows.
- **Interpolation curve changes:** Comfort-category cubic; slower sitting and independent contact tracks.
- **Rig/deformer corrections:** Rounded sitting feet, protected head silhouettes and torso paw anchors.
- **Secondary motion added:** Slow independent breath and blanket edge response.
- **Juicing added:** Subtle posture/cheek change; no playful effects.
- **Frame-by-frame corrections:** Sampled contact/recovery poses reviewed in both color roles; shared own-head arm mask and original-outline preservation apply. Rounded sitting feet, protected head silhouettes and torso paw anchors.
- **Interaction timing:** 8.8 seconds in gentle mode; shy ?1.15, playful ?0.88. Held contact extends the timeline where supported.
- **User gesture controls:** Hold/release or accessible button; tap tucks blanket when not holding.
- **Expected emotional effect:** Relaxed closeness.
- **Performance notes:** One shared vector rig/ticker per visible scene; bounded effects and no external mesh. Device GPU timing remains unmeasured.
- **Testing result:** Full 120-Hz timeline/anchor/reach checks and 240?220 rendering in both color roles passed. Six-pose raster review performed; device acceptance remains pending.
- **Actual modified assets:** bear_choreography.dart, bear_vector_rig.dart, bear_scene.dart and player_screen.dart (paths in the source table).
- **Unresolved limitations:** Blanket is a vector layer; no cloth mesh was supplied. Editable Rive source and physical Android verification remain external/pending.

### 15. Goodnight Kiss

- **Category:** Cozy
- **Original animation problems:** Same standing sleep scene as Sleep Together; no distinct kiss.
- **New key poses:** Rest ? tuck blanket ? forehead approach ? kiss ? closed eyes ? retreat ? dim.
- **Inbetweening improvements:** Separate continuous root, head, paw, eye and reaction tracks connect the listed breakdown poses; direction changes ease through their authored windows.
- **Interpolation curve changes:** Soft kiss windows, continuous blanket rise and late lighting fade.
- **Rig/deformer corrections:** Apply resting posture before the forehead contact solve; corrected 11.7-pixel mismatch.
- **Secondary motion added:** Sleep breathing, ear relaxation and soft eye transitions.
- **Juicing added:** One small contact heart and gentle dimming.
- **Frame-by-frame corrections:** Sampled contact/recovery poses reviewed in both color roles; shared own-head arm mask and original-outline preservation apply. Apply resting posture before the forehead contact solve; corrected 11.7-pixel mismatch.
- **Interaction timing:** 9.2 seconds in gentle mode; shy ?1.15, playful ?0.88. Held contact extends the timeline where supported.
- **User gesture controls:** Tap lamp/scene to change dimming.
- **Expected emotional effect:** Reassurance before sleep.
- **Performance notes:** One shared vector rig/ticker per visible scene; bounded effects and no external mesh. Device GPU timing remains unmeasured.
- **Testing result:** Full 120-Hz timeline/anchor/reach checks and 240?220 rendering in both color roles passed. Six-pose raster review performed; device acceptance remains pending.
- **Actual modified assets:** bear_choreography.dart, bear_vector_rig.dart, bear_scene.dart and player_screen.dart (paths in the source table).
- **Unresolved limitations:** Lighting is a tint over the original room, not an external authored lighting asset. Editable Rive source and physical Android verification remain external/pending.

### 16. Sleep Together

- **Category:** Cozy
- **Original animation problems:** Two standing bears behind a static blanket, perfectly shared motion.
- **New key poses:** Adjust ? recline beside one another ? paws meet ? eyes close ? blanket settles ? independent breathing.
- **Inbetweening improvements:** Separate continuous root, head, paw, eye and reaction tracks connect the listed breakdown poses; direction changes ease through their authored windows.
- **Interpolation curve changes:** Separate recline/eye timelines with a quiet final loop.
- **Rig/deformer corrections:** Rigid head/torso rotations, seated foot correction and common paw target.
- **Secondary motion added:** Different breath frequencies/phases and small ears.
- **Juicing added:** Calm dimming and breathing blanket; no repeated bursts.
- **Frame-by-frame corrections:** Sampled contact/recovery poses reviewed in both color roles; shared own-head arm mask and original-outline preservation apply. Rigid head/torso rotations, seated foot correction and common paw target.
- **Interaction timing:** 10 seconds in gentle mode; shy ?1.15, playful ?0.88. Held contact extends the timeline where supported.
- **User gesture controls:** Tap moves closer; swipe wakes and blends to neutral.
- **Expected emotional effect:** Safe, quiet companionship.
- **Performance notes:** One shared vector rig/ticker per visible scene; bounded effects and no external mesh. Device GPU timing remains unmeasured.
- **Testing result:** Full 120-Hz timeline/anchor/reach checks and 240?220 rendering in both color roles passed. Six-pose raster review performed; device acceptance remains pending.
- **Actual modified assets:** bear_choreography.dart, bear_vector_rig.dart, bear_scene.dart and player_screen.dart (paths in the source table).
- **Unresolved limitations:** Reclining uses existing vector silhouettes rather than a new fully horizontal drawing set. Editable Rive source and physical Android verification remain external/pending.

### 17. Comfort Hug

- **Category:** Comfort
- **Original animation problems:** Indistinguishable from warm hug; no sad-to-reassured recipient arc.
- **New key poses:** Sad posture ? sender notices ? slow approach ? gentle contact ? recipient relaxes ? held breath ? release.
- **Inbetweening improvements:** Separate continuous root, head, paw, eye and reaction tracks connect the listed breakdown poses; direction changes ease through their authored windows.
- **Interpolation curve changes:** Slower category cubic and restrained sway frequency.
- **Rig/deformer corrections:** Same protected contact rig with recipient posture corrected before recovery.
- **Secondary motion added:** Slow breath, lowered ears gradually lifting, soft smile.
- **Juicing added:** Minimal compression; discrete contact feedback.
- **Frame-by-frame corrections:** Sampled contact/recovery poses reviewed in both color roles; shared own-head arm mask and original-outline preservation apply. Same protected contact rig with recipient posture corrected before recovery.
- **Interaction timing:** 9.6 seconds in gentle mode; shy ?1.15, playful ?0.88. Held contact extends the timeline where supported.
- **User gesture controls:** Hold/Let go; tap repeats when not holding.
- **Expected emotional effect:** Reassurance without energetic bounce.
- **Performance notes:** One shared vector rig/ticker per visible scene; bounded effects and no external mesh. Device GPU timing remains unmeasured.
- **Testing result:** Full 120-Hz timeline/anchor/reach checks and 240?220 rendering in both color roles passed. Six-pose raster review performed; device acceptance remains pending.
- **Actual modified assets:** bear_choreography.dart, bear_vector_rig.dart, bear_scene.dart and player_screen.dart (paths in the source table).
- **Unresolved limitations:** No external facial mesh or replacement Rive drawing was created. Editable Rive source and physical Android verification remain external/pending.

### 18. Dry Your Tears

- **Category:** Comfort
- **Original animation problems:** Both bears were sad; the tear disappeared abruptly on tap.
- **New key poses:** Sad recipient ? sender reaches ? cheek contact ? curved wipe ? tear fades ? blink/smile ? lower paw.
- **Inbetweening improvements:** Separate continuous root, head, paw, eye and reaction tracks connect the listed breakdown poses; direction changes ease through their authored windows.
- **Interpolation curve changes:** Independent reach, wipe arc and tear-opacity tracks.
- **Rig/deformer corrections:** Cheek anchor follows the lowered head; arm stays within its reach limit.
- **Secondary motion added:** Delayed blink and softened ears.
- **Juicing added:** Single tear and small cheek reaction, without excess effects.
- **Frame-by-frame corrections:** Sampled contact/recovery poses reviewed in both color roles; shared own-head arm mask and original-outline preservation apply. Cheek anchor follows the lowered head; arm stays within its reach limit.
- **Interaction timing:** 7.2 seconds in gentle mode; shy ?1.15, playful ?0.88. Held contact extends the timeline where supported.
- **User gesture controls:** Tap/accessible action advances the wipe promptly; it also resolves in the authored timeline.
- **Expected emotional effect:** Being noticed and comforted.
- **Performance notes:** One shared vector rig/ticker per visible scene; bounded effects and no external mesh. Device GPU timing remains unmeasured.
- **Testing result:** Full 120-Hz timeline/anchor/reach checks and 240?220 rendering in both color roles passed. Six-pose raster review performed; device acceptance remains pending.
- **Actual modified assets:** bear_choreography.dart, bear_vector_rig.dart, bear_scene.dart and player_screen.dart (paths in the source table).
- **Unresolved limitations:** The tear is a vector drop; no fluid simulation or external cheek mesh. Editable Rive source and physical Android verification remain external/pending.

### 19. I Miss You

- **Category:** Comfort
- **Original animation problems:** Static standing pair under a moon; no lonely seated posture or arrival.
- **New key poses:** Recipient sits/sighs ? sender notices/joins ? gaze turns ? paws meet ? soft smile.
- **Inbetweening improvements:** Separate continuous root, head, paw, eye and reaction tracks connect the listed breakdown poses; direction changes ease through their authored windows.
- **Interpolation curve changes:** Long emotional approach and delayed recipient reach.
- **Rig/deformer corrections:** Sitting feet and shared lower hand-contact target.
- **Secondary motion added:** Quiet breath, gradual ear recovery and gaze.
- **Juicing added:** Existing moon atmosphere without extra particles.
- **Frame-by-frame corrections:** Sampled contact/recovery poses reviewed in both color roles; shared own-head arm mask and original-outline preservation apply. Sitting feet and shared lower hand-contact target.
- **Interaction timing:** 9.4 seconds in gentle mode; shy ?1.15, playful ?0.88. Held contact extends the timeline where supported.
- **User gesture controls:** Moon/scene tap reveals the existing protected note.
- **Expected emotional effect:** Loneliness easing into companionship.
- **Performance notes:** One shared vector rig/ticker per visible scene; bounded effects and no external mesh. Device GPU timing remains unmeasured.
- **Testing result:** Full 120-Hz timeline/anchor/reach checks and 240?220 rendering in both color roles passed. Six-pose raster review performed; device acceptance remains pending.
- **Actual modified assets:** bear_choreography.dart, bear_vector_rig.dart, bear_scene.dart and player_screen.dart (paths in the source table).
- **Unresolved limitations:** Sender is visible during the opening; no new offscreen arrival artwork. Editable Rive source and physical Android verification remain external/pending.

### 20. One Umbrella

- **Category:** Comfort
- **Original animation problems:** Static canopy; tap shifted roots abruptly; no hand-held pivot.
- **New key poses:** Rainy room ? sender brings/raises canopy ? recipient notices ? moves under ? paws join handle.
- **Inbetweening improvements:** Separate continuous root, head, paw, eye and reaction tracks connect the listed breakdown poses; direction changes ease through their authored windows.
- **Interpolation curve changes:** Soft approach and input-driven eased extra closeness.
- **Rig/deformer corrections:** Umbrella pivots at its handle; recipient reaches the handle target.
- **Secondary motion added:** Small canopy lag; heads retain their spacing.
- **Juicing added:** Consistent window rain; static rain in reduced motion.
- **Frame-by-frame corrections:** Sampled contact/recovery poses reviewed in both color roles; shared own-head arm mask and original-outline preservation apply. Umbrella pivots at its handle; recipient reaches the handle target.
- **Interaction timing:** 7.2 seconds in gentle mode; shy ?1.15, playful ?0.88. Held contact extends the timeline where supported.
- **User gesture controls:** Tap umbrella/scene or Come closer.
- **Expected emotional effect:** Shared shelter and reassurance.
- **Performance notes:** One shared vector rig/ticker per visible scene; bounded effects and no external mesh. Device GPU timing remains unmeasured.
- **Testing result:** Full 120-Hz timeline/anchor/reach checks and 240?220 rendering in both color roles passed. Six-pose raster review performed; device acceptance remains pending.
- **Actual modified assets:** bear_choreography.dart, bear_vector_rig.dart, bear_scene.dart and player_screen.dart (paths in the source table).
- **Unresolved limitations:** Rain remains in the existing window scene; no new outdoor background. Editable Rive source and physical Android verification remain external/pending.

### 21. A Little Flower

- **Category:** Surprises
- **Original animation problems:** Fixed visible flower; tap changed size instantly.
- **New key poses:** Hidden flower ? shy glance ? curved reveal ? surprised recipient ? handoff ? bloom.
- **Inbetweening improvements:** Separate continuous root, head, paw, eye and reaction tracks connect the listed breakdown poses; direction changes ease through their authored windows.
- **Interpolation curve changes:** Overlapping reveal/receive cubics and a damped bloom pulse.
- **Rig/deformer corrections:** Prop follows the offer path and receiver paw target.
- **Secondary motion added:** Flower wobble, head tilt and delayed blush.
- **Juicing added:** Persistent bloom plus a bounded brief sparkle.
- **Frame-by-frame corrections:** Sampled contact/recovery poses reviewed in both color roles; shared own-head arm mask and original-outline preservation apply. Prop follows the offer path and receiver paw target.
- **Interaction timing:** 7.2 seconds in gentle mode; shy ?1.15, playful ?0.88. Held contact extends the timeline where supported.
- **User gesture controls:** Tap/Bloom for me blooms and reveals the existing note.
- **Expected emotional effect:** A thoughtful little gift.
- **Performance notes:** One shared vector rig/ticker per visible scene; bounded effects and no external mesh. Device GPU timing remains unmeasured.
- **Testing result:** Full 120-Hz timeline/anchor/reach checks and 240?220 rendering in both color roles passed. Six-pose raster review performed; device acceptance remains pending.
- **Actual modified assets:** bear_choreography.dart, bear_vector_rig.dart, bear_scene.dart and player_screen.dart (paths in the source table).
- **Unresolved limitations:** Five vector petals; no external flower animation asset. Editable Rive source and physical Android verification remain external/pending.

### 22. Heart Delivery

- **Category:** Surprises
- **Original animation problems:** Heart stayed fixed between idle bears; no weight or handoff.
- **New key poses:** Carry ? steps ? small stumble ? recover ? offer ? receive ? settled heart.
- **Inbetweening improvements:** Separate continuous root, head, paw, eye and reaction tracks connect the listed breakdown poses; direction changes ease through their authored windows.
- **Interpolation curve changes:** Damped weight shift plus separate offering/acceptance cubics.
- **Rig/deformer corrections:** Isolated body lean, anchored paw/heart transfer and volume compensation.
- **Secondary motion added:** Heart follows a curved offer with delayed receiver reaction.
- **Juicing added:** Bounded weight compression and blush.
- **Frame-by-frame corrections:** Sampled contact/recovery poses reviewed in both color roles; shared own-head arm mask and original-outline preservation apply. Isolated body lean, anchored paw/heart transfer and volume compensation.
- **Interaction timing:** 7.2 seconds in gentle mode; shy ?1.15, playful ?0.88. Held contact extends the timeline where supported.
- **User gesture controls:** Heart/scene tap reveals the existing protected note.
- **Expected emotional effect:** An earnest, slightly clumsy gift.
- **Performance notes:** One shared vector rig/ticker per visible scene; bounded effects and no external mesh. Device GPU timing remains unmeasured.
- **Testing result:** Full 120-Hz timeline/anchor/reach checks and 240?220 rendering in both color roles passed. Six-pose raster review performed; device acceptance remains pending.
- **Actual modified assets:** bear_choreography.dart, bear_vector_rig.dart, bear_scene.dart and player_screen.dart (paths in the source table).
- **Unresolved limitations:** The heart is a lightweight vector prop, not a physics body. Editable Rive source and physical Android verification remain external/pending.

### 23. A Tiny Surprise

- **Category:** Surprises
- **Original animation problems:** Box lid jumped instantly from closed to open.
- **New key poses:** Place box ? curiosity lean ? suspense ? lid lifts/rotates ? heart reveal ? small startle ? smile.
- **Inbetweening improvements:** Separate continuous root, head, paw, eye and reaction tracks connect the listed breakdown poses; direction changes ease through their authored windows.
- **Interpolation curve changes:** Continuous lid/reveal tracks and bounded surprise hop.
- **Rig/deformer corrections:** Lid/heart/body order corrected; box stays planted.
- **Secondary motion added:** Head lean precedes the reaction; ears settle after the pop.
- **Juicing added:** Small heart, brief four-stroke sparkle and ?4-pixel startle.
- **Frame-by-frame corrections:** Sampled contact/recovery poses reviewed in both color roles; shared own-head arm mask and original-outline preservation apply. Lid/heart/body order corrected; box stays planted.
- **Interaction timing:** 7.2 seconds in gentle mode; shy ?1.15, playful ?0.88. Held contact extends the timeline where supported.
- **User gesture controls:** Tap/Unwrap accelerates opening and reveals the note; an opened lid stays open.
- **Expected emotional effect:** Readable anticipation followed by delight.
- **Performance notes:** One shared vector rig/ticker per visible scene; bounded effects and no external mesh. Device GPU timing remains unmeasured.
- **Testing result:** Full 120-Hz timeline/anchor/reach checks and 240?220 rendering in both color roles passed. Six-pose raster review performed; device acceptance remains pending.
- **Actual modified assets:** bear_choreography.dart, bear_vector_rig.dart, bear_scene.dart and player_screen.dart (paths in the source table).
- **Unresolved limitations:** Uses the existing heart surprise, not a new random gift inventory. Editable Rive source and physical Android verification remain external/pending.

### 24. A Shy Confession

- **Category:** Surprises
- **Original animation problems:** Shared static large-heart scene, indistinguishable from Heart Delivery.
- **New key poses:** Approach ? look away ? breath/pause ? small heart appears ? extend ? receive ? mutual blush.
- **Inbetweening improvements:** Separate continuous root, head, paw, eye and reaction tracks connect the listed breakdown poses; direction changes ease through their authored windows.
- **Interpolation curve changes:** Later offer window (.45?.63), delayed receipt and soft recovery.
- **Rig/deformer corrections:** Small hidden prop follows the arm path; head stays rigid.
- **Secondary motion added:** Nervous gaze, tiny head tilt, independent breath and gradual blush.
- **Juicing added:** A small heart and restrained expression; no impact bounce.
- **Frame-by-frame corrections:** Sampled contact/recovery poses reviewed in both color roles; shared own-head arm mask and original-outline preservation apply. Small hidden prop follows the arm path; head stays rigid.
- **Interaction timing:** 9 seconds in gentle mode; shy ?1.15, playful ?0.88. Held contact extends the timeline where supported.
- **User gesture controls:** Heart/scene tap reveals the existing protected note.
- **Expected emotional effect:** Nervousness resolving into warmth.
- **Performance notes:** One shared vector rig/ticker per visible scene; bounded effects and no external mesh. Device GPU timing remains unmeasured.
- **Testing result:** Full 120-Hz timeline/anchor/reach checks and 240?220 rendering in both color roles passed. Six-pose raster review performed; device acceptance remains pending.
- **Actual modified assets:** bear_choreography.dart, bear_vector_rig.dart, bear_scene.dart and player_screen.dart (paths in the source table).
- **Unresolved limitations:** Emotional acting uses the original tiny features; no new facial artwork library. Editable Rive source and physical Android verification remain external/pending.
