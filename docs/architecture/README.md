# Bear With Me architecture

Android-first Flutter 3.47 / Dart 3.13 application. iOS and web scaffolds are
included. The backend consists only of Firebase Auth and Firestore Standard
edition, with optional App Check. No Functions, Storage, Admin SDK, billing
account, backend proxy or automatic FCM sender is used by the app.

## Trust boundaries

Authentication establishes an account identity, not couple membership. Two
specific UIDs in `firebase/firestore.rules` are the sole membership authority.
The corresponding client defines only help the UI address the other account;
changing those defines does not grant database access.

Registration creates a self-only profile before membership is configured.
Unapproved registrations cannot discover another profile, invite, pair, world,
moment or memory. Profiles contain no writable membership claims.

## Pairing state machine

1. The creator generates 32 bytes using Dart `Random.secure`. A 43-character
   base64url secret is shared privately. Only its SHA-256 digest is used as the
   invitation document ID. No short numeric-code fallback is present.
2. A transaction creates the pending invitation and `privatePair/main`. Rules
   require both records to agree, the other fixed member as receiver, a server
   creation time, a maximum 24-hour expiration, and zero approvals. The client
   chooses 23 hours to tolerate modest clock drift; server rules are decisive.
3. The receiver submits the token. Its digest addresses one document. An atomic
   transaction accepts the invitation and moves the pair to `confirming`.
4. Each account separately appends only its own UID to `approvedBy`. The second
   confirmation atomically activates the pair and creates its world document.
   A forged second approval is denied. Expired confirmations are denied.
5. Either member may revoke the pair. All old world reads and writes immediately
   fail server rules. Re-pairing requires a fresh invitation and a fresh world ID.
   Old records never become accessible again through the new pairing.

The invitation is not persisted by the creator's app. Leaving that screen means
revoking and replacing a lost invitation. Existing client caches cannot be
remotely erased from another device; revocation prevents future server access.

## Surprise protocol

`couples/{invitationDigest}/moments/{requestId}` contains only the two UIDs,
creation/open/play times and a fixed generic label. It never contains the
interaction type, note, scene, variant, thumbnail or other revealing content.

`payloads/{requestId}` contains the immutable type, variant, note and character
roles. It is readable by the sender, or by the receiver after an authorized
reveal. Collection listing is always denied, including to the sender.

Sending writes both documents atomically in a **Firestore transaction**, rather
than an offline-queued batch. This deliberately refines the suggested batch
procedure: transactions fail offline, so a surprise is not sent later without
the user's knowledge. A stable request ID and a server read make connection
retries idempotent. An existing request is accepted as sent only when the sender,
type, message and variant match. Edited content needs a new request.

Opening is a separate receiver-only transaction. `openedAt` must change from
null to `request.time` using `serverTimestamp`, with no other changed fields.
Only after that transaction succeeds does the client request the individual
payload from `Source.server`. UI navigation and replay never implicitly submit
an unopened reveal. Playback completion is a separate, one-time receiver write.

This is a Firestore access-state boundary. It does not prove that a physical
human pressed a button, and it is not end-to-end encryption. A modified
authorized receiver can deliberately submit its permitted reveal operation.
Firebase project administrators can read ordinary stored messages.

## State and local data

Riverpod providers scope authentication, profile, partner, pair, inbox, outgoing
history, world theme, memories, settings and live sessions. Private providers
depend on the authenticated UID and active pair, dispose their listeners, and
clear the repository's in-memory opened-payload map when disposed. GoRouter
guards all private routes. `/studio` is an explicit local-only preview, never a
fake authenticated session or simulated delivery.

Firestore disk persistence is disabled on every configured platform. Reveals
and payload reads always require server authorization. Opened payloads may be
replayed offline from the current session's in-memory cache. Logout clears that
map, scoped drafts, and auth state. Firebase Auth manages session credentials;
the app never stores a password. Neither a logout nor revocation can erase
screenshots, copied notes or another device's already-held memory.

User-requested local composition drafts are the one intentionally persisted
private item. SharedPreferences keys include the account UID and interaction
type, and drafts are removed on successful sending, logout or local-data clear.
They are ordinary app-private local storage, not encrypted archival storage.
Automatic queued sending is not implemented. Authentication data is managed by
the Firebase SDK, independently of these noncredential preferences.

## Quotas and queries

Inbox and outgoing listeners each subscribe to at most 30 metadata documents.
Older inbox pages use a descending timestamp cursor and 30-document limits.
Unread badges describe the currently synchronized recent inbox. The memory
book also uses 30-document pages. Timestamp and document-ID cursors preserve
pagination when records share a creation time. Payloads are fetched individually
only for playback.

One send normally writes two documents, a reveal writes one, completion writes
one, and saving a memory writes one small reference. Rules perform additional
authorization reads. Reconnection and listener changes also consume reads.
No frame position, breathing cycle, particle or touch sample is sent online.
Together mode sends logical actions at most once per second, validated in rules.

As checked against official documentation on 2026-10-30, the default Standard
database free quota is 1 GiB stored, 50,000 reads/day, 20,000 writes/day, 20,000
deletes/day, and 10 GiB outbound transfer/month. Daily reset is around midnight
Pacific time. One database per project qualifies for free quota. TTL, backups,
PITR, restore and clone operations require billing and are not enabled here.
Quota errors produce a friendly retry-later message; the app never upgrades a
plan. See https://firebase.google.com/docs/firestore/quotas and
https://firebase.google.com/docs/projects/billing/firebase-pricing-plans.

## Animation and optional live room

The bundled CustomPainter uses original, separate vector layers for both bears,
references the supplied caramel and white designs, and supplies functional
development motion and gesture feedback. It is **not a completed Rive export**.
The 24 interactions are catalogued, persisted and authorized; their development
poses share reusable scene logic. Bespoke production choreography remains part
of the authoring work in `docs/animations/AUTHORING.md`.

The Rive 0.14.11 adapter uses FileLoader, RiveWidgetBuilder, ViewModel data
binding, and explicit resource disposal. `USE_AUTHORED_RIVE=true` is opt-in after
the specified asset is authored. Failed loading falls back to the Flutter
renderer. It does not substitute an unrelated third-party bear file.

Together mode uses one bounded latest-session listener. The initiator invites,
the other member accepts, and either sends ordered logical actions. Sequence
numbers advance transactionally. It is an approximate shared room, not a
frame-synchronized game server. No background notifications or automatic
presence claims are made.
