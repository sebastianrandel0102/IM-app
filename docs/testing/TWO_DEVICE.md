# Two-account acceptance test

This checklist must be executed on two Android devices before calling the app
production-verified. Emulator rules tests do not prove real-device delivery,
attestation, battery behavior, sound or platform accessibility.

1. Verify the project stays on Spark, Email/Password is enabled, the default
   Standard database exists, rules/indexes are deployed and both UIDs match.
2. Install the configured build on device A and B. Register and log in separately.
   Kill and relaunch each app; sessions restore to the correct account.
3. A creates an invitation, B accepts it, and both independently confirm. Try
   another account: no private pair, profile or world access should be possible.
4. A selects Warm Hug, writes a note and sends. Wait for success. B's foreground
   inbox updates with a generic sealed envelope. There must be no type, note or
   scene thumbnail before opening. Background push is intentionally not promised.
5. On B, press Open Surprise. Hold to keep the hug, release gently, try the
   accessible hold button, and replay. Save the moment. Restart the app and
   confirm it remains in B's memory book when online.
6. B sends Cheek Kiss to A. Verify the correct white→brown roles, explicit reveal,
   kiss gesture feedback, return-kiss control and independent playback completion.
7. Try airplane mode before sending: draft remains and no Delivered state appears.
   Reconnect and retry the same request; only one moment is created. If its
   connection outcome was uncertain, check From You history before a new draft.
8. Try airplane mode before opening: reveal must fail. Reconnect and retry;
   the moment must still be available. Replay a previously opened moment from
   the current in-memory session cache offline. Logout removes that cache.
9. Enable reduced motion and the system's animation accessibility preference.
   Confirm no bouncing/spinning or moving rain; all controls remain usable.
   Check text scaling and TalkBack, 48px tap targets, mute, sound and haptics.
10. Change theme on A and see it on B. Accessories affect only the selected bear.
    Join the optional live room, accept on B, send a logical action in each
    direction, and close the room. Network delays may shift timing.
11. Favorite and remove a saved memory. Verify the other account cannot read B's
    individually saved book. Original history remains after a bookmark removal.
12. Disconnect. Both devices leave the private world; old server reads fail.
    Re-pair with a fresh token; old history must not reappear.
13. Exercise account deletion using disposable emulator users first. Confirm a
    recent password is required, pairing is revoked, and retained shared data
    cleanup is performed separately by the project owner.

Record device model, OS, app version, rules deployment, account UID aliases,
test date and pass/fail. Do not include private passwords, notes or tokens.
