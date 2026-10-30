import 'package:cloud_firestore/cloud_firestore.dart';

import '../../affection/data/affection_repository.dart';
import '../../affection/domain/models.dart';

class LiveSessionRepository {
  LiveSessionRepository(this.affection);
  final AffectionRepository affection;
  CollectionReference<Json> get sessions =>
      affection.collection('liveSessions');
  Stream<LiveInteractionSession?> watch() => sessions
      .orderBy('updatedAt', descending: true)
      .limit(1)
      .snapshots()
      .map(
        (s) => s.docs.isEmpty
            ? null
            : LiveInteractionSession.fromDoc(s.docs.first),
      );
  Future<void> invite() => sessions.add({
    'initiatorUid': affection.uid,
    'status': 'invited',
    'currentAction': 'wave',
    'eventSequence': 0,
    'updatedAt': FieldValue.serverTimestamp(),
  });
  Future<void> status(String id, String status) => sessions.doc(id).update({
    'status': status,
    'updatedAt': FieldValue.serverTimestamp(),
  });
  Future<void> action(String id, String action) async {
    await affection.db.runTransaction((tx) async {
      final ref = sessions.doc(id);
      final doc = await tx.get(ref);
      if (!doc.exists || doc.data()!['status'] != 'active') {
        throw StateError('This little room has closed.');
      }
      tx.update(ref, {
        'currentAction': action,
        'eventSequence': (doc.data()!['eventSequence'] as int) + 1,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
