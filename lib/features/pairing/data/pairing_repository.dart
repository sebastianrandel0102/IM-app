import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';

import '../../../app/configuration/bootstrap.dart';
import '../../affection/domain/affection_type.dart';
import '../../affection/domain/models.dart';

String generateInvitationToken() =>
    base64UrlEncode(List<int>.generate(32, (_) => Random.secure().nextInt(256)))
        .replaceAll('=', '');
String invitationIdFor(String token) {
  if (!RegExp(r'^[A-Za-z0-9_-]{43}$').hasMatch(token)) {
    throw const FormatException('Paste the complete 43-character invitation.');
  }
  return sha256.convert(utf8.encode(token)).toString();
}

class PairingRepository {
  PairingRepository(this.db, this.uid);
  final FirebaseFirestore db;
  final String uid;
  DocumentReference<Json> get pairRef =>
      db.collection('privatePair').doc('main');
  Future<String> create(BearCharacter bear) async {
    final other = AppConfig.partnerOf(uid);
    if (other == null || other.isEmpty) {
      throw StateError(
        'Your two account UIDs must be configured before pairing. Your UID is available below.',
      );
    }
    final token = generateInvitationToken();
    final id = invitationIdFor(token);
    final invite = db.collection('pairInvitations').doc(id);
    await db.runTransaction((tx) async {
      final existing = await tx.get(pairRef);
      if (existing.exists && existing.data()!['status'] != 'revoked') {
        throw StateError(
          'An invitation or pairing already exists. Revoke it before starting again.',
        );
      }
      tx.set(invite, {
        'creatorUid': uid,
        'intendedReceiverUid': other,
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(
          DateTime.now().add(const Duration(hours: 23)),
        ),
        'status': 'pending',
      });
      tx.set(pairRef, {
        'memberUids': [uid, other],
        'creatorUid': uid,
        'receiverUid': other,
        'creatorBear': bear.name,
        'invitationId': id,
        'status': 'pending',
        'approvedBy': <String>[],
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
    return token;
  }

  Future<void> join(String token) async {
    final id = invitationIdFor(token.trim());
    final invite = db.collection('pairInvitations').doc(id);
    await db.runTransaction((tx) async {
      final invitation = await tx.get(invite);
      final pair = await tx.get(pairRef);
      if (!invitation.exists || !pair.exists) {
        throw StateError('This invitation could not be found.');
      }
      final d = invitation.data()!;
      if (d['intendedReceiverUid'] != uid || d['creatorUid'] == uid) {
        throw StateError('This invitation belongs to the other bear.');
      }
      if (d['status'] != 'pending' ||
          pair.data()!['invitationId'] != id ||
          pair.data()!['status'] != 'pending') {
        throw StateError('This invitation is no longer available.');
      }
      if (dateOf(d['expiresAt'])!.isBefore(DateTime.now())) {
        throw StateError('This invitation has expired. Ask for a fresh one.');
      }
      tx.update(invite, {'status': 'accepted'});
      tx.update(pairRef, {'status': 'confirming'});
    });
  }

  Future<void> confirm() async {
    await db.runTransaction((tx) async {
      final doc = await tx.get(pairRef);
      final pair = CouplePair.fromDoc(doc);
      if (pair.status != 'confirming') {
        throw StateError('Your partner needs to accept the invitation first.');
      }
      if (pair.approvedBy.contains(uid)) return;
      final approvals = [...pair.approvedBy, uid];
      tx.update(pairRef, {
        'approvedBy': approvals,
        'status': approvals.length == 2 ? 'active' : 'confirming',
      });
      if (approvals.length == 2) {
        tx.set(db.collection('couples').doc(pair.invitationId), {
          'memberUids': [pair.creatorUid, pair.receiverUid],
          'themeId': SceneTheme.cozyRoom.name,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  Future<void> revoke() async {
    await db.runTransaction((tx) async {
      final doc = await tx.get(pairRef);
      if (doc.exists && doc.data()!['status'] != 'revoked') {
        tx.update(pairRef, {'status': 'revoked'});
      }
    });
  }
}
