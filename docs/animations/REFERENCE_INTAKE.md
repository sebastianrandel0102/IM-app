# Reference intake — 1 November 2026

Read before changing the artwork. The full master prompt is accessible at
`C:/Users/HERNANDEZ/.codex/attachments/39a4dbb4-ee89-4354-b0a3-5d329c9ad9c5/Pasted text.txt`
(44,192 bytes, 2,485 lines). No separate `bear_with_me_full_physics_prompt.md`
was found. This attachment contains the complete 45-section master specification.

All four pictures were visually inspected **inline in the user message**. There
are no local PNG attachments with these names in the attachments directory,
project, Downloads or parent workspace. The labels below associate the pictures
in message order with the requested names; they are not verified file names.
Dimensions describe the supplied conversation images, not file metadata.

| Requested name | Available reference | Image dimensions | Implementation purpose |
| --- | --- | --- | --- |
| `01_white_bear_character_sheet.png` | First inline image; no local path | 1536 × 1024 | Rounded head, small body, white fill, circular pink cheeks, single pink ear marking; standing, three-quarter, profile, seated, curled sleeping and open-arm silhouettes. |
| `02_brown_bear_character_sheet.png` | Second inline image; no local path | 1536 × 1024 | Caramel fill, cream oval muzzle, tiny eyes, downward forked mouth, short limbs, small outlined ear marking; matching seated/sleeping replacements. |
| `03_hug_cuddle_storyboard.png` | Third inline image; no local path | 1774 × 887 | Open-arm anticipation, torso contact, staggered near/far wraps, settled heads, seated shoulder support and couch staging. |
| `04_touch_physics_storyboard.png` | Fourth inline image; no local path | 1536 × 1024 | Head-pet tilt, nose surprise, belly response, joined paws, shared spin and quiet blanket-covered rest. |

Neither original character illustration is supplied as an identifiable image.
Consequently an original-versus-sheet likeness comparison cannot be performed.
The existing vector contours are the preservation baseline. No reference sheet
is shipped as a full-body image or displayed in the application.

## Inconsistencies and decisions

- Ear markings change sides or disappear across storyboard views. The white
  sheet consistently shows a small pink mark on its visible right ear; it does
  not show two large pink ear interiors. Keep the small marking on the readable
  front ear, including when the face turns, and hide it on rear views.
- The brown sheet uses a small downward forked mouth. Storyboards sometimes add
  a broad smile, tongue and pink cheeks. Retain the sheet's small mouth and use
  eyes/posture for happiness; allow restrained temporary blush.
- Head/body ratios, limb lengths and muzzle sizes vary between panels. Keep
  one coordinate system and bounded limbs, using authored corrective contours
  for sitting and lying rather than stretching a standing character.
- The cuddle panels exchange left/right positions. Roles may reverse without
  reversing time or changing the character's identifying details.
- The touch storyboard is an example of physical expression. It is not a
  talking feature; there is no microphone, speech, lip sync or chat addition.

## Initial audit and checkpoint

Git was clean at `01f3eb0`. A tracked-source archive is stored locally at
`.tools/physics-before-20261101.zip`. The active implementation is Dart vector
artwork and a shared deterministic two-actor timeline. Rive is installed, but
there is no `.riv` or editable Rive source, so the existing vector system is
retained. Existing pose/contact tests and all 24 gesture identifiers exist.

The baseline image `artifacts/animations/contact-rig/contact-brown.png` was
actually opened and inspected. Confirmed issues:

| Area | Severity | Finding |
| --- | --- | --- |
| Warm/Spinning Hug | Critical | Front arms form thin diagonal neck-level bands; near shoulders remain hidden behind heads and the embrace is hard to read. |
| Comfort Hug | Major | Has seated support and a sad-to-relaxed face, but shares the neck-level wrap and a minimally staged seat. |
| Cuddle Time | Major | Has shared head rest but the lower cushion and tiny forward feet do not communicate the reference couch clearly. |
| Sleep Together | Major | Uses a horizontal torso replacement, but mostly upright heads and a narrow blanket obscure the curled silhouettes. |
| Goodnight Kiss | Major | Dedicated sleeping recipient and forehead solve exist; temple-touch paw reach needs verification against the rendered paw, not just its requested anchor. |
| Character identity | Major | Two large inner-ear patches and the same upward mouth on both characters conflict with the new sheets. |
| Secondary motion | Major | Analytic wobble exists, but no fixed-step physical response to touch. |
| Touch/UI | Major | No moving local hit zones, stroke/hold recognition, local expressive reactions or persisted intensity setting. |

Later results and remaining acceptance are recorded in `PHYSICS_IMPLEMENTATION.md`.
