# Touch Echo audit — 1 November 2026

Root: `D:/VS Files/IM-app`. Flutter 3.47.7, Dart 3.13.5. No AGENTS.md
was found at the project or its ancestors. The entire 33-section master prompt
was read before changes. Initial git status contained only the untracked prompt.

The four inline references were inspected in message order: white sheet
(1536×1024), brown sheet (1536×1024), hug storyboard (1774×887), touch
storyboard (1536×1024). These dimensions describe the inline images. No local
reference PNGs or original drawings exist in assets/reference or the attachments
directory. Existing editable vector contours are the identity baseline.
The existing contact-brown.png rendered contact sheet was opened as a baseline.

## Implementation map

| Area | Existing implementation | Touch Echo change |
| --- | --- | --- |
| Art | bear_artwork.dart, bear_vector_rig.dart: separate vector head, ears, torso, two arms, feet, face | Reuse art; publish additional anchors and local hit geometry |
| Motion | bear_choreography.dart, bear_physics.dart: shared poses, bounded two-link arms, fixed 60 Hz springs | Dedicated deterministic TouchPlayback contact tracks and continuous local reaction |
| Input | bear_touch.dart: six zones, single stroke callback; BearScene gesture arena | Dedicated normalized pointer lifecycle, metrics, ambiguity/cancel results |
| State/routes | Riverpod, GoRouter, guarded private routes, explicit local studio | Add private /touch and local /studio/touch |
| Delivery | AffectionRepository: atomic envelope/payload, idempotent online transaction | Optional typed touch payload, persistent account/world-scoped pending intent |
| Privacy | Receiver-only openedAt then Source.server payload read, no collection listing | Retain reveal boundary, generic envelope, immutable reply reference |
| Inbox/memory | 30-document listeners/pages, personal memory references | Reuse existing streams/routes and memory ownership |
| Pairing | privatePair/main, two-account allowlist, active invitation world | Derive sender, recipient, bear roles from active pair; add no UIDs |
| Settings | reducedMotion, haptics, animationIntensity, sound, notification preference | Reuse; add sensitivity, receive/block Touch Echo preference |
| Backend | Auth + Firestore, persistence disabled, optional App Check | No Functions, Storage, credentials, push sender or billing changes |

Baseline analyzer, complete Flutter tests and Android debug build were started
before modification; actual outcomes are recorded in HANDOFF.md. Existing
Firebase emulator scripts use demo-bear-with-me and a portable Node/JDK.

## Decisions and risks

Keep the current trust model and 24 gesture data unchanged. Touch payloads adapt
to legacy gesture categories only for compatibility; playback uses their own
versioned choreography. Sealed envelopes never contain touch type or parameters.
The receiver's allowed reveal is an access-state boundary, not proof of a tap.
Persistent pending intents use local app preferences, are not encrypted, and
must be scoped to UID and invitation so a replacement pair cannot receive them.
Rules are tested locally before any production deployment. Device feel, visual
polish and native frame budgets require actual hardware acceptance; screenshots
and synthetic tests alone cannot establish those qualities.

Official references checked during implementation:
- https://firebase.google.com/docs/firestore/manage-data/transactions
- https://firebase.google.com/docs/firestore/security/rules-fields
- https://firebase.google.com/docs/projects/billing/firebase-pricing-plans
