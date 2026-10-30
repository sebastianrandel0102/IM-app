import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/configuration/bootstrap.dart';
import '../../features/affection/data/affection_repository.dart';
import '../../features/affection/domain/models.dart';
import '../../features/authentication/data/authentication_repository.dart';
import '../../features/pairing/data/pairing_repository.dart';

final authProvider = StreamProvider<User?>((ref) {
  if (!ref.watch(bootstrapProvider).ready) return Stream.value(null);
  return FirebaseAuth.instance.authStateChanges();
});
final authRepositoryProvider = Provider(
  (ref) => AuthenticationRepository(
    FirebaseAuth.instance,
    FirebaseFirestore.instance,
  ),
);
final currentProfileProvider = StreamProvider.autoDispose<AppUser?>((ref) {
  final user = ref.watch(authProvider).value;
  if (user == null) return Stream.value(null);
  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .snapshots()
      .map((d) => d.exists ? AppUser.fromDoc(d) : null);
});
final pairProvider = StreamProvider.autoDispose<CouplePair?>((ref) {
  final user = ref.watch(authProvider).value;
  if (user == null || AppConfig.partnerOf(user.uid) == null) {
    return Stream.value(null);
  }
  return FirebaseFirestore.instance
      .collection('privatePair')
      .doc('main')
      .snapshots()
      .map((d) {
        if (!d.exists) return null;
        final p = CouplePair.fromDoc(d);
        return p.contains(user.uid) ? p : null;
      });
});
final pairingRepositoryProvider = Provider.autoDispose(
  (ref) => PairingRepository(
    FirebaseFirestore.instance,
    ref.watch(authProvider).value!.uid,
  ),
);
final partnerProvider = StreamProvider.autoDispose<AppUser?>((ref) {
  final user = ref.watch(authProvider).value;
  final pair = ref.watch(pairProvider).value;
  if (user == null || pair == null || !pair.active) return Stream.value(null);
  return FirebaseFirestore.instance
      .collection('users')
      .doc(pair.otherUid(user.uid))
      .snapshots()
      .map((d) => d.exists ? AppUser.fromDoc(d) : null);
});
final affectionRepositoryProvider = Provider.autoDispose<AffectionRepository?>((
  ref,
) {
  final user = ref.watch(authProvider).value;
  final pair = ref.watch(pairProvider).value;
  if (user == null || pair == null || !pair.active) return null;
  final repository = AffectionRepository(
    FirebaseFirestore.instance,
    user.uid,
    pair,
  );
  ref.onDispose(repository.clearSession);
  return repository;
});
final inboxProvider = StreamProvider.autoDispose<List<AffectionMoment>>((ref) {
  final repo = ref.watch(affectionRepositoryProvider);
  return repo == null ? Stream.value([]) : InboxRepository(repo).watch();
});
final outgoingProvider = StreamProvider.autoDispose<List<AffectionMoment>>((
  ref,
) {
  final repo = ref.watch(affectionRepositoryProvider);
  return repo == null
      ? Stream.value([])
      : InboxRepository(repo).watch(outgoing: true);
});
final memoriesProvider = StreamProvider.autoDispose<List<SavedMemory>>((ref) {
  final repo = ref.watch(affectionRepositoryProvider);
  return repo == null ? Stream.value([]) : MemoryRepository(repo).watch();
});
final worldProvider = StreamProvider.autoDispose<Json?>((ref) {
  final repo = ref.watch(affectionRepositoryProvider);
  return repo == null
      ? Stream.value(null)
      : FirebaseFirestore.instance
            .collection('couples')
            .doc(repo.pair.invitationId)
            .snapshots()
            .map((d) => d.data());
});
