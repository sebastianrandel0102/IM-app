import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bear_with_me/features/affection/data/affection_repository.dart';
import 'package:bear_with_me/features/affection/domain/affection_type.dart';
import 'package:bear_with_me/features/affection/domain/models.dart';
import 'package:bear_with_me/features/touch_echo/data/touch_echo_repository.dart';
import 'package:bear_with_me/features/touch_echo/domain/touch_intent.dart';

// Transport substitution is confined to unit tests of local persistence and
// acknowledgments. Real Firebase authorization/delivery has separate emulators.
class UnusedFirestore extends Fake implements FirebaseFirestore {}

AffectionRepository base({String uid = 'owner', String world = 'world'}) =>
    AffectionRepository(
      UnusedFirestore(),
      uid,
      CouplePair(
        invitationId: world,
        creatorUid: 'owner',
        receiverUid: 'partner',
        creatorBear: BearCharacter.brown,
        status: 'active',
        approvedBy: const ['owner', 'partner'],
      ),
    );
TouchIntent pet() => TouchIntent(
  kind: TouchKind.headPet,
  style: TouchStyle.gentle,
  intensity: .3,
  durationMs: 1800,
  seed: 123,
);
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('rapid explicit sends produce one commit and never show sent before acknowledgment', () async {
    final ack = Completer<void>();
    var commits = 0;
    final repo = TouchEchoRepository(
      base(),
      currentUid: () => 'owner',
      commitTouch: (id, intent, reply) {
        commits++;
        return ack.future;
      },
    );
    await repo.ready;
    final first = repo.submit('stable-id', pet());
    await Future<void>.delayed(Duration.zero);
    await repo.submit('other-id', pet());
    expect(commits, 1);
    expect(repo.state, TouchFlowState.sendPending);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('touch_outbox_owner_world'), contains('stable-id'));
    ack.complete();
    await first;
    expect(repo.state, TouchFlowState.sent);
    expect(prefs.getString('touch_outbox_owner_world'), isNull);
    repo.dispose();
  });
  test('offline failure persists the same ID across restart and removes it after server acknowledgment', () async {
    final ids = <String>[];
    final first = TouchEchoRepository(
      base(),
      currentUid: () => 'owner',
      commitTouch: (id, intent, reply) async {
        ids.add(id);
        throw FirebaseException(plugin: 'cloud_firestore', code: 'unavailable');
      },
    );
    await first.ready;
    await first.submit('same-id', pet(), replyTo: 'original');
    expect(first.state, TouchFlowState.sendPending);
    first.dispose();
    final second = TouchEchoRepository(
      base(),
      currentUid: () => 'owner',
      commitTouch: (id, intent, reply) async {
        ids.add(id);
        expect(reply, 'original');
      },
    );
    await second.ready;
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(ids, ['same-id', 'same-id']);
    expect(second.state, TouchFlowState.sent);
    second.dispose();
  });
  test('a different account/world cannot restore a queued touch; revoked writes stop retrying', () async {
    final first = TouchEchoRepository(
      base(),
      currentUid: () => 'owner',
      commitTouch: (_, _, _) async {
        throw FirebaseException(plugin: 'cloud_firestore', code: 'unavailable');
      },
    );
    await first.ready;
    await first.submit('private-id', pet());
    first.dispose();
    var leaked = false;
    final other = TouchEchoRepository(
      base(uid: 'partner'),
      currentUid: () => 'partner',
      commitTouch: (_, _, _) async {
        leaked = true;
      },
    );
    final newWorld = TouchEchoRepository(
      base(world: 'new-world'),
      currentUid: () => 'owner',
      commitTouch: (_, _, _) async {
        leaked = true;
      },
    );
    await other.ready;
    await newWorld.ready;
    expect(leaked, false);
    expect(other.pendingIntent, isNull);
    expect(newWorld.pendingIntent, isNull);
    other.dispose();
    newWorld.dispose();
    final revoked = TouchEchoRepository(
      base(),
      currentUid: () => 'owner',
      commitTouch: (_, _, _) async {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'permission-denied',
        );
      },
    );
    await revoked.ready;
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(revoked.state, TouchFlowState.failed);
    await revoked.discard();
    expect(revoked.state, TouchFlowState.idle);
    revoked.dispose();
  });
}
