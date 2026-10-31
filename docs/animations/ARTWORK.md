# Editable bear artwork handoff

Update, 1 November 2026: four inline character/storyboard images are now
available. The original two illustrations and separate reference PNG files are
still unavailable. See [REFERENCE_INTAKE.md](REFERENCE_INTAKE.md) and
[PHYSICS_IMPLEMENTATION.md](PHYSICS_IMPLEMENTATION.md) for the current reference
decisions, corrected ear/mouth details and horizontal resting implementation.
The older manual handoff below describes the earlier baseline.

The app's existing artwork is the design source available in this workspace.
The original two reference images are absent. Both generated masters preserve
the current palette, oversized rounded head, tiny face, caramel muzzle and
white bear's pink inner ears and baseline cheeks. No reference likeness test
or accurate image trace is claimed.

## Generate and edit

Run `flutter test test/animation_foundation_test.dart`. It exports:

- `artifacts/animations/masters/brown.svg`
- `artifacts/animations/masters/white.svg`

Open either SVG in Inkscape. The canvas is 1024×1024 with a transparent
background. `BearRoot` uses `translate(512 860) scale(4.2)`; all child coordinates
match the rig's logical units. The complete white lower body is included.
`BearArtwork.head`, `.torso` and `.mouth` in Dart are the shared contour source
for those live paths and SVG exports. Neutral arm sections are an editable
breakdown of the procedural rig's curved arm. The live rig does not load SVGs.

Choose **Object → Objects and Layers** to select named groups. Neutral eyes and
mouth start visible; closed/happy/sleepy/surprised eyes and alternate mouths are
hidden using `display="none"`. Hide neutral groups before showing replacements.
White cheeks stay visible in every expression; increase their opacity for blush.
The SVG's separate foot paths overlap the lower leg shape; keep that hidden
overlap when moving them. Arm outline and fill sections are separate so their
seam can remain covered. Do not stretch the face with the torso.

## Rig coordinate contract

| Control | Logical location / rule |
| --- | --- |
| Root | Runtime defaults (132,278) sender and (268,278) recipient in a 400×340 scene |
| Torso | Existing body/hip transform, bounded squash with reciprocal horizontal scale |
| Head origin | Body-local `(headX,-113+headY-breath)` |
| Neck pivot | Head-local `(0,50)`; both drawing and contact transforms use it |
| Ear origins | Head-local `(-36.5,-38)` and `(42.5,-38)` |
| Ear rotation pivot | Ear-local `(0,18)`, near the base, with delayed settling |
| Shoulders | Body-local `(23,-80)` and `(-23,-80)` |
| Neutral paw targets | Body-local `(27,-39)` and `(-28,-40)` |
| Arm reach | 64 logical units maximum; procedural outward elbow bend; no vertex weights |
| Legs | Hip/leg origin at x=±16, y≈−31; local swing arcs lift ankles up to 4 units |
| Primary face contact | `BearPose.anchor`: nose/profile, cheek silhouette and forehead |
| Additional anchors | Head center, both cheek patches, both shoulders, paws, chest, hug, seat and back |

`BearPose.headPoint` and `bodyPoint` convert local anchors to scene coordinates
including facing, body rotation, head rotation, breathing, sit and squash.
`BearVectorRig.paw` returns the actual bounded endpoint, not just a requested
target. Use it when validating contact. Mirroring transforms targets as well
as the pose; the action timeline always runs forward.

## Exact remaining manual authoring

1. Obtain the **original two image files** for a faithful reconstruction. Import
   each into its master as a locked reference layer at about 30% opacity. Match
   head/ear silhouette, eye spacing, muzzle, mouth, cheek positions and outline
   character against that image before changing the current artwork. The white
   lower body must use the same rounded proportions; compare both at equal scale.
2. Author fully horizontal sleeping replacement contours and matching shoulders,
   blanket edge, muzzle/forehead and paw anchors. The current runtime delivers a
   reclined rigid-part pose; rotating it farther without new drawings breaks
   short-arm contact or pushes the large head offstage.
3. Author front/three-quarter/back/side turn drawings for a full rotational hug
   and a rear-view carrier/rider. The current upright projected orbit preserves
   existing art but cannot expose an unprovided back view. Check the foreground
   arm/head masks frame by frame when crossing depth order.
4. For an optional mesh runtime, import these verified layers into an authoring
   tool with an available export license. Place bones at the listed pivots; keep
   face vertices outside torso/neck weights, add only bend-region mesh points,
   and inspect shoulder/neck extremes and contact compression. No editable mesh
   project or binary is included here. Do not rename an SVG to `.riv`.
5. Follow [AUTHORING.md](AUTHORING.md) for the optional Rive artboard/input
   contract. Test with the installed Rive 0.14 API adapter before enabling
   `USE_AUTHORED_RIVE`. Confirm export access in the user's own account; no
   subscription was purchased and Rive export was not available in this session.
6. Raster-review the exact contact frames in both color roles, then profile on
   an ordinary Android device. Recheck grip, feet, layer crossings, return kiss,
   hold cancellation, muted sound, reduced motion and resume behavior.

The Flutter source stays the working implementation until these external assets
have actually been authored, exported and verified. Generated masters are a
usable editing handoff, not evidence that those remaining steps are complete.
