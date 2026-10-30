import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/affection_type.dart';
import '../domain/models.dart';

class AffectionRepository {
  AffectionRepository(this.db, this.uid, this.pair);
  final FirebaseFirestore db;
  final String uid;
  final CouplePair pair;
  final Map<String, ProtectedMomentPayload> _opened = {};
  CollectionReference<Json> collection(String name) =>
      db.collection('couples').doc(pair.invitationId).collection(name);
  String newId() => collection('moments').doc().id;

  Future<void> sendAffection({
    required String requestId,
    required AffectionType type,
    required String variant,
    required String message,
  }) async {
    if (message.length > 500) {
      throw ArgumentError('Keep your little note to 500 characters.');
    }
    if (!AffectionVariant.values.any((v) => v.name == variant)) {
      throw ArgumentError('Choose a valid variation.');
    }
    final metadata = collection('moments').doc(requestId);
    final payload = collection('payloads').doc(requestId);
    // Transactions fail offline instead of silently queuing a surprise. The stable
    // request ID also makes a retry after an uncertain connection idempotent.
    await db.runTransaction((tx) async {
      final existing = await tx.get(metadata);
      if (existing.exists) {
        final oldPayload = await tx.get(payload);
        final d = oldPayload.data();
        if (existing.data()!['senderUid'] != uid ||
            d?['interactionType'] != type.name ||
            d?['personalMessage'] != message ||
            d?['animationVariant'] != variant) {
          throw StateError(
            'This draft was already sent. Start a new moment to change it.',
          );
        }
        return;
      }
      tx.set(metadata, {
        'senderUid': uid,
        'receiverUid': pair.otherUid(uid),
        'createdAt': FieldValue.serverTimestamp(),
        'openedAt': null,
        'playedAt': null,
        'genericLabel': 'A little surprise arrived.',
      });
      tx.set(payload, {
        'senderUid': uid,
        'receiverUid': pair.otherUid(uid),
        'interactionType': type.name,
        'animationVariant': variant,
        'personalMessage': message,
        'senderBear': pair.bearFor(uid).name,
        'receiverBear': pair.bearFor(uid).other.name,
        'assetVersion': 1,
      });
    }, maxAttempts: 3);
  }

  Future<ProtectedMomentPayload> openSurprise(String momentId) async {
    final meta = collection('moments').doc(momentId);
    await db.runTransaction((tx) async {
      final doc = await tx.get(meta);
      if (!doc.exists) throw StateError('This moment could not be found.');
      final d = doc.data()!;
      if (d['receiverUid'] != uid) {
        throw StateError('Only the receiving bear can open this surprise.');
      }
      if (d['openedAt'] == null) {
        tx.update(meta, {'openedAt': FieldValue.serverTimestamp()});
      }
    }, maxAttempts: 3);
    return readOpened(momentId);
  }

  Future<ProtectedMomentPayload> readOpened(String momentId) async {
    // Never trust cached metadata as authority to reveal a sealed payload.
    final doc = await collection('payloads')
        .doc(momentId)
        .get(const GetOptions(source: Source.server));
    if (!doc.exists) {
      throw StateError(
        'The note could not load. Your moment is safe; please retry.',
      );
    }
    final result = ProtectedMomentPayload.fromDoc(doc);
    _opened[momentId] = result;
    return result;
  }

  ProtectedMomentPayload? cachedOpened(String id) => _opened[id];
  void clearSession() => _opened.clear();
  Future<void> complete(String id) async {
    final ref = collection('moments').doc(id);
    await db.runTransaction((tx) async {
      final doc = await tx.get(ref);
      final d = doc.data();
      if (d == null || d['receiverUid'] != uid || d['openedAt'] == null) return;
      if (d['playedAt'] == null) {
        tx.update(ref, {'playedAt': FieldValue.serverTimestamp()});
      }
    });
  }
}

class InboxRepository {
  InboxRepository(this.affection);
  final AffectionRepository affection;
  Stream<List<AffectionMoment>> watch({bool outgoing = false}) => affection
      .collection('moments')
      .where(outgoing ? 'senderUid' : 'receiverUid', isEqualTo: affection.uid)
      .orderBy('createdAt', descending: true)
      .orderBy(FieldPath.documentId, descending: true)
      .limit(30)
      .snapshots()
      .map((s) => s.docs.map(AffectionMoment.fromDoc).toList());
  Future<List<AffectionMoment>> older(
    AffectionMoment before, {
    bool outgoing = false,
  }) async =>
      (await affection
              .collection('moments')
              .where(
                outgoing ? 'senderUid' : 'receiverUid',
                isEqualTo: affection.uid,
              )
              .orderBy('createdAt', descending: true)
              .orderBy(FieldPath.documentId, descending: true)
              .startAfter([Timestamp.fromDate(before.createdAt!), before.id])
              .limit(30)
              .get(const GetOptions(source: Source.server)))
          .docs
          .map(AffectionMoment.fromDoc)
          .toList();
}

class MemoryRepository {
  MemoryRepository(this.affection);
  final AffectionRepository affection;
  CollectionReference<Json> get refs => affection.collection('memories');
  Stream<List<SavedMemory>> watch() => refs
      .where('savedByUid', isEqualTo: affection.uid)
      .orderBy('createdAt', descending: true)
      .orderBy(FieldPath.documentId, descending: true)
      .limit(30)
      .snapshots()
      .map((s) => s.docs.map(SavedMemory.fromDoc).toList());
  Future<List<SavedMemory>> older(SavedMemory before) async =>
      (await refs
              .where('savedByUid', isEqualTo: affection.uid)
              .orderBy('createdAt', descending: true)
              .orderBy(FieldPath.documentId, descending: true)
              .startAfter([Timestamp.fromDate(before.createdAt!), before.id])
              .limit(30)
              .get(const GetOptions(source: Source.server)))
          .docs
          .map(SavedMemory.fromDoc)
          .toList();
  Future<void> save(ProtectedMomentPayload payload) async {
    final id = '${affection.uid}_${payload.momentId}';
    await affection.db.runTransaction((tx) async {
      final ref = refs.doc(id);
      if ((await tx.get(ref)).exists) return;
      tx.set(ref, {
        'momentId': payload.momentId,
        'savedByUid': affection.uid,
        'caption': payload.type.title,
        'favorite': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> favorite(SavedMemory memory) =>
      refs.doc(memory.id).update({'favorite': !memory.favorite});
  Future<void> remove(String id) => refs.doc(id).delete();
}
