import 'package:cloud_firestore/cloud_firestore.dart';

import 'affection_type.dart';

typedef Json = Map<String, dynamic>;
DateTime? dateOf(Object? value) => value is Timestamp ? value.toDate() : null;
String stringOf(Json data, String key, {int max = 1000}) {
  final value = data[key];
  if (value is! String || value.length > max) {
    throw FormatException('Invalid $key in this moment.');
  }
  return value;
}

class AppUser {
  const AppUser({
    required this.uid,
    required this.displayName,
    required this.accessory,
  });
  final String uid, displayName, accessory;
  factory AppUser.fromDoc(DocumentSnapshot<Json> doc) {
    final data = doc.data()!;
    return AppUser(
      uid: doc.id,
      displayName: stringOf(data, 'displayName', max: 40),
      accessory: data['accessory'] as String? ?? 'none',
    );
  }
}

class CouplePair {
  const CouplePair({
    required this.invitationId,
    required this.creatorUid,
    required this.receiverUid,
    required this.creatorBear,
    required this.status,
    required this.approvedBy,
  });
  final String invitationId, creatorUid, receiverUid, status;
  final BearCharacter creatorBear;
  final List<String> approvedBy;
  bool get active => status == 'active';
  bool contains(String uid) => uid == creatorUid || uid == receiverUid;
  String otherUid(String uid) => uid == creatorUid ? receiverUid : creatorUid;
  BearCharacter bearFor(String uid) =>
      uid == creatorUid ? creatorBear : creatorBear.other;
  factory CouplePair.fromDoc(DocumentSnapshot<Json> doc) {
    final d = doc.data()!;
    return CouplePair(
      invitationId: stringOf(d, 'invitationId'),
      creatorUid: stringOf(d, 'creatorUid'),
      receiverUid: stringOf(d, 'receiverUid'),
      creatorBear: BearCharacter.parse(d['creatorBear']),
      status: stringOf(d, 'status'),
      approvedBy: List<String>.from(d['approvedBy'] as List),
    );
  }
}

class PairInvitation {
  const PairInvitation(
    this.id,
    this.creatorUid,
    this.receiverUid,
    this.expiresAt,
    this.status,
  );
  final String id, creatorUid, receiverUid, status;
  final DateTime expiresAt;
  factory PairInvitation.fromDoc(DocumentSnapshot<Json> doc) {
    final d = doc.data()!;
    return PairInvitation(
      doc.id,
      stringOf(d, 'creatorUid'),
      stringOf(d, 'intendedReceiverUid'),
      dateOf(d['expiresAt'])!,
      stringOf(d, 'status'),
    );
  }
}

class AffectionMoment {
  const AffectionMoment({
    required this.id,
    required this.senderUid,
    required this.receiverUid,
    this.createdAt,
    this.openedAt,
    this.playedAt,
  });
  final String id, senderUid, receiverUid;
  final DateTime? createdAt, openedAt, playedAt;
  factory AffectionMoment.fromDoc(DocumentSnapshot<Json> doc) {
    final d = doc.data()!;
    return AffectionMoment(
      id: doc.id,
      senderUid: stringOf(d, 'senderUid'),
      receiverUid: stringOf(d, 'receiverUid'),
      createdAt: dateOf(d['createdAt']),
      openedAt: dateOf(d['openedAt']),
      playedAt: dateOf(d['playedAt']),
    );
  }
}

class ProtectedMomentPayload {
  const ProtectedMomentPayload({
    required this.momentId,
    required this.type,
    required this.variant,
    required this.personalMessage,
    required this.senderBear,
    required this.receiverBear,
  });
  final String momentId, variant, personalMessage;
  final AffectionType type;
  final BearCharacter senderBear, receiverBear;
  factory ProtectedMomentPayload.fromDoc(DocumentSnapshot<Json> doc) {
    final d = doc.data()!;
    if (d['assetVersion'] != 1) {
      throw const FormatException('Update the app to play this moment.');
    }
    final variant = stringOf(d, 'animationVariant');
    if (!AffectionVariant.values.any((e) => e.name == variant)) {
      throw const FormatException('Unknown animation variation.');
    }
    final sender = BearCharacter.parse(d['senderBear']);
    final receiver = BearCharacter.parse(d['receiverBear']);
    if (sender == receiver) {
      throw const FormatException('This moment’s bears could not be loaded.');
    }
    return ProtectedMomentPayload(
      momentId: doc.id,
      type: AffectionType.parse(stringOf(d, 'interactionType')),
      variant: variant,
      personalMessage: stringOf(d, 'personalMessage', max: 500),
      senderBear: sender,
      receiverBear: receiver,
    );
  }
}

class SavedMemory {
  const SavedMemory({
    required this.id,
    required this.momentId,
    required this.caption,
    required this.favorite,
    this.createdAt,
  });
  final String id, momentId, caption;
  final bool favorite;
  final DateTime? createdAt;
  factory SavedMemory.fromDoc(DocumentSnapshot<Json> doc) {
    final d = doc.data()!;
    return SavedMemory(
      id: doc.id,
      momentId: stringOf(d, 'momentId'),
      caption: stringOf(d, 'caption', max: 120),
      favorite: d['favorite'] == true,
      createdAt: dateOf(d['createdAt']),
    );
  }
}

class LiveInteractionSession {
  const LiveInteractionSession({
    required this.id,
    required this.initiatorUid,
    required this.status,
    required this.action,
    required this.sequence,
    this.actionSenderUid,
    this.updatedAt,
  });
  final String id, initiatorUid, status, action;
  final int sequence;
  final String? actionSenderUid;
  final DateTime? updatedAt;
  String get actorUid => actionSenderUid ?? initiatorUid;
  factory LiveInteractionSession.fromDoc(DocumentSnapshot<Json> doc) {
    final d = doc.data()!;
    return LiveInteractionSession(
      id: doc.id,
      initiatorUid: stringOf(d, 'initiatorUid'),
      status: stringOf(d, 'status'),
      action: stringOf(d, 'currentAction'),
      sequence: d['eventSequence'] as int,
      actionSenderUid: d['actionSenderUid'] as String?,
      updatedAt: dateOf(d['updatedAt']),
    );
  }
}
